import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

/// Firestore에 실제 저장된 일정을 실시간으로 표시하는 일정 탭 화면입니다.
/// 기존 하단 네비게이션의 일정 탭에 ScheduleScreen을 연결해서 사용합니다.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _showUpcoming = true;

  final FirestoreService _firestoreService = FirestoreService();
  final List<_DemoSchedule> _schedules = [];
  StreamSubscription<List<SavedScheduleRecord>>? _scheduleSubscription;
  bool _loadingSchedules = true;
  Object? _scheduleError;

  @override
  void initState() {
    super.initState();
    _listenToSchedules();
  }

  void _listenToSchedules() {
    _scheduleSubscription?.cancel();
    _scheduleSubscription = _firestoreService.watchSchedules().listen(
          (records) {
        if (!mounted) return;
        setState(() {
          _schedules
            ..clear()
            ..addAll(records.map(_DemoSchedule.fromSavedRecord));
          _loadingSchedules = false;
          _scheduleError = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _loadingSchedules = false;
          _scheduleError = error;
        });
      },
    );
  }

  void _retryLoadingSchedules() {
    setState(() {
      _loadingSchedules = true;
      _scheduleError = null;
    });
    _listenToSchedules();
  }

  @override
  void dispose() {
    _scheduleSubscription?.cancel();
    super.dispose();
  }

  List<_DemoSchedule> get _visibleSchedules => _schedules
      .where((schedule) => schedule.isPast == !_showUpcoming)
      .toList()
  // 예정/지난 일정 모두 날짜 내림차순: 날짜가 더 늦은 일정이 위에 표시됩니다.
    ..sort((a, b) => b.date.compareTo(a.date));

  Future<void> _openDetail(_DemoSchedule schedule) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _ScheduleDetailScreen(
          schedule: schedule,
          onChanged: () {
            if (mounted) setState(() {});
          },
          onDelete: () async {
            final deleted = await _deleteSchedule(schedule);
            if (deleted && mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<bool> _deleteSchedule(_DemoSchedule schedule) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          '일정을 삭제할까요?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Text(
          '“${schedule.title}” 일정이 목록에서 삭제돼요.\n삭제한 일정은 되돌릴 수 없어요.',
          style: const TextStyle(color: _SchedulePalette.secondaryText, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소', style: TextStyle(color: _SchedulePalette.secondaryText)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _SchedulePalette.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return false;

    try {
      await _firestoreService.deleteSchedule(schedule.id);
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정을 삭제했어요.')),
      );
      // 일정 목록은 Firestore 실시간 구독 결과로 자동 갱신됩니다.
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정을 삭제하지 못했어요.\n$e')),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSchedules) {
      return Scaffold(
        backgroundColor: _SchedulePalette.background,
        body: const SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _SchedulePalette.primary),
                SizedBox(height: 14),
                Text('저장된 일정을 불러오고 있어요.', style: TextStyle(color: _SchedulePalette.secondaryText)),
              ],
            ),
          ),
        ),
      );
    }

    if (_scheduleError != null) {
      return Scaffold(
        backgroundColor: _SchedulePalette.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 44, color: _SchedulePalette.primary),
                  const SizedBox(height: 14),
                  const Text('일정을 불러오지 못했어요.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _SchedulePalette.text)),
                  const SizedBox(height: 8),
                  Text('로그인 상태와 Firestore 권한을 확인해주세요.\n$_scheduleError', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, height: 1.5, color: _SchedulePalette.secondaryText)),
                  const SizedBox(height: 18),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _SchedulePalette.primary),
                    onPressed: _retryLoadingSchedules,
                    child: const Text('다시 불러오기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final items = _visibleSchedules;
    final upcomingCount = _schedules.where((item) => !item.isPast).length;

    return Scaffold(
      backgroundColor: _SchedulePalette.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          const Text(
                            '일정',
                            style: TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w900,
                              color: _SchedulePalette.text,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '저장된 일정',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: _SchedulePalette.text,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            '함께할 약속을 한곳에 모아보세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: _SchedulePalette.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3EDE8),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _ScheduleTabPill(
                                    label: '예정 $upcomingCount',
                                    selected: _showUpcoming,
                                    onTap: () => setState(() => _showUpcoming = true),
                                  ),
                                ),
                                Expanded(
                                  child: _ScheduleTabPill(
                                    label: '지난 일정',
                                    selected: !_showUpcoming,
                                    onTap: () => setState(() => _showUpcoming = false),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyScheduleState(
                        isUpcoming: _showUpcoming,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                            padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 16),
                            child: _ScheduleCard(
                              schedule: items[index],
                              onTap: () => _openDetail(items[index]),
                              onDelete: () { _deleteSchedule(items[index]); },
                              onEdit: () => _openDetail(items[index]),
                            ),
                          ),
                          childCount: items.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _ScheduleTabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ScheduleTabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _SchedulePalette.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _SchedulePalette.secondaryText,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final _DemoSchedule schedule;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ScheduleCard({
    required this.schedule,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final firstStop = schedule.stops.isNotEmpty ? schedule.stops.first : null;
    final thumbnails = schedule.stops.take(3).toList();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      elevation: 1.5,
      shadowColor: const Color(0x14000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 15, 15, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _formatDateWithWeekday(schedule.date),
                    style: const TextStyle(
                      fontSize: 13,
                      color: _SchedulePalette.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 28,
                    width: 28,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert_rounded, color: _SchedulePalette.secondaryText, size: 21),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onSelected: (value) {
                        if (value == 'delete') onDelete();
                        if (value == 'edit') onEdit();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('일정 수정')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('일정 삭제', style: TextStyle(color: _SchedulePalette.danger)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      schedule.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        color: _SchedulePalette.text,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (!schedule.isPast) ...[
                    const SizedBox(width: 9),
                    const _AiBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ParticipantAvatars(names: schedule.participants),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      schedule.participants.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: _SchedulePalette.secondaryText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 20, color: _SchedulePalette.secondaryText),
                  const SizedBox(width: 8),
                  Text(
                    '${schedule.startTime} – ${schedule.endTime}',
                    style: const TextStyle(fontSize: 14, color: _SchedulePalette.secondaryText),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, size: 20, color: _SchedulePalette.secondaryText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      schedule.stops.map((stop) => stop.name).join('  →  '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: _SchedulePalette.secondaryText, height: 1.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  for (var i = 0; i < thumbnails.length; i++) ...[
                    if (i > 0) const SizedBox(width: 9),
                    Expanded(child: _StopThumbnail(stop: thumbnails[i], compact: thumbnails.length == 1)),
                  ],
                ],
              ),
              if (firstStop != null && schedule.isPast) ...[
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: _SchedulePalette.mintDark, size: 16),
                    SizedBox(width: 5),
                    Text('완료한 일정', style: TextStyle(color: _SchedulePalette.mintDark, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _SchedulePalette.mint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'AI 맞춤 코스',
        style: TextStyle(fontSize: 11, color: _SchedulePalette.mintDark, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ParticipantAvatars extends StatelessWidget {
  final List<String> names;
  const _ParticipantAvatars({required this.names});

  @override
  Widget build(BuildContext context) {
    final visible = names.take(3).toList();
    return SizedBox(
      width: visible.length == 1 ? 27 : 27 + (visible.length - 1) * 17,
      height: 29,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * 17,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: [const Color(0xFFFFD8C0), const Color(0xFFD8E7E2), const Color(0xFFE8DFFF)][i % 3],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  visible[i].isNotEmpty ? visible[i][0] : '?',
                  style: const TextStyle(fontSize: 11, color: _SchedulePalette.text, fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StopThumbnail extends StatelessWidget {
  final _DemoStop stop;
  final bool compact;
  const _StopThumbnail({required this.stop, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 104 : 88,
      decoration: BoxDecoration(
        color: stop.tint,
        borderRadius: BorderRadius.circular(13),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -8,
            bottom: -12,
            child: Icon(
              _iconForStop(stop.category),
              size: compact ? 82 : 68,
              color: Colors.white.withOpacity(0.52),
            ),
          ),
          Center(child: Text(stop.emoji, style: TextStyle(fontSize: compact ? 35 : 30))),
          if (compact)
            Positioned(
              left: 8,
              right: 8,
              bottom: 7,
              child: Text(
                stop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: _SchedulePalette.text, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForStop(String category) {
    if (category.contains('카페') || category.contains('베이커리')) return Icons.local_cafe_rounded;
    if (category.contains('공원') || category.contains('산책')) return Icons.park_rounded;
    if (category.contains('시장')) return Icons.storefront_rounded;
    return Icons.restaurant_rounded;
  }
}

class _EmptyScheduleState extends StatelessWidget {
  final bool isUpcoming;
  const _EmptyScheduleState({required this.isUpcoming});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(color: _SchedulePalette.peach, shape: BoxShape.circle),
              child: const Icon(Icons.calendar_month_rounded, size: 34, color: _SchedulePalette.primary),
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? '아직 저장된 일정이 없어요' : '지난 일정이 없어요',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _SchedulePalette.text),
            ),
            const SizedBox(height: 7),
            const Text(
              '마음에 드는 코스를 저장하고\n약속을 한곳에서 관리해보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _SchedulePalette.secondaryText, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleDetailScreen extends StatefulWidget {
  final _DemoSchedule schedule;
  final VoidCallback onChanged;
  final Future<void> Function() onDelete;

  const _ScheduleDetailScreen({
    required this.schedule,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<_ScheduleDetailScreen> {
  _DemoSchedule get schedule => widget.schedule;

  Future<void> _editSchedule() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: schedule.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: '약속 날짜 선택',
      cancelText: '취소',
      confirmText: '선택',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: _SchedulePalette.primary),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;

    final start = _parseTime(schedule.startTime);
    final pickedStart = await showTimePicker(context: context, initialTime: start, helpText: '시작 시간 선택');
    if (pickedStart == null || !mounted) return;

    final end = _parseTime(schedule.endTime);
    final pickedEnd = await showTimePicker(context: context, initialTime: end, helpText: '종료 시간 선택');
    if (pickedEnd == null || !mounted) return;

    final newDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
    final newStartTime = _formatTime(pickedStart);
    final newEndTime = _formatTime(pickedEnd);

    try {
      await FirestoreService().updateSchedule(
        scheduleId: schedule.id,
        date: newDate,
        startTime: newStartTime,
        endTime: newEndTime,
      );
      if (!mounted) return;
      setState(() {
        schedule.date = newDate;
        schedule.startTime = newStartTime;
        schedule.endTime = newEndTime;
      });
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정을 수정했어요.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일정을 수정하지 못했어요.\n$e')),
      );
    }
  }

  TimeOfDay _parseTime(String text) {
    final parts = text.split(':');
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 12, minute: int.tryParse(parts[1]) ?? 0);
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SchedulePalette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  ),
                  const Expanded(
                    child: Text(
                      '일정 상세',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _SchedulePalette.text),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded, size: 25),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onSelected: (value) {
                      if (value == 'edit') _editSchedule();
                      if (value == 'delete') widget.onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('일정 수정')),
                      PopupMenuItem(value: 'delete', child: Text('일정 삭제', style: TextStyle(color: _SchedulePalette.danger))),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RouteMapPreview(stops: schedule.stops),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 0),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  schedule.title,
                                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: _SchedulePalette.text, letterSpacing: -0.6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const _AiBadge(),
                            ],
                          ),
                          const SizedBox(height: 17),
                          _DetailInfoRow(icon: Icons.calendar_month_rounded, text: _formatFullDate(schedule.date)),
                          const SizedBox(height: 10),
                          _DetailInfoRow(
                            icon: Icons.access_time_rounded,
                            text: '${schedule.startTime} – ${schedule.endTime}  ·  총 ${_durationLabel(schedule.startTime, schedule.endTime)}',
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_alt_outlined, size: 21, color: _SchedulePalette.secondaryText),
                              const SizedBox(width: 10),
                              _ParticipantAvatars(names: schedule.participants),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  schedule.participants.join(', '),
                                  style: const TextStyle(fontSize: 13, color: _SchedulePalette.secondaryText),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Divider(height: 1, color: _SchedulePalette.divider),
                          ),
                          for (var i = 0; i < schedule.stops.length; i++)
                            _TimelineStop(
                              stop: schedule.stops[i],
                              index: i,
                              isLast: i == schedule.stops.length - 1,
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editSchedule,
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      label: const Text('일정 수정'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _SchedulePalette.mintDark,
                        side: const BorderSide(color: _SchedulePalette.mintDark, width: 1.1),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 19),
                      label: const Text('일정 삭제'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _SchedulePalette.danger,
                        side: const BorderSide(color: Color(0xFFFFC8C4), width: 1.1),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteMapPreview extends StatelessWidget {
  final List<_DemoStop> stops;
  const _RouteMapPreview({required this.stops});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 258,
      width: double.infinity,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final positions = <Offset>[
              Offset(width * 0.20, height * 0.20),
              Offset(width * 0.79, height * 0.43),
              Offset(width * 0.49, height * 0.78),
            ];
            return Stack(
              children: [
                const Positioned.fill(child: CustomPaint(painter: _MapBackdropPainter())),
                Positioned.fill(child: CustomPaint(painter: _TriangleRoutePainter(positions: positions))),
                Positioned(
                  left: width * 0.46,
                  top: height * 0.46,
                  child: const Text('광명시', style: TextStyle(fontSize: 17, color: Color(0xFF67717B), fontWeight: FontWeight.w800)),
                ),
                for (var i = 0; i < math.min(3, stops.length); i++)
                  Positioned(
                    left: _labelLeft(width, positions[i].dx, i),
                    top: _labelTop(height, positions[i].dy, i),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: width * 0.38),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 7, offset: Offset(0, 2))],
                      ),
                      child: Text(
                        stops[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _SchedulePalette.text),
                      ),
                    ),
                  ),
                for (var i = 0; i < math.min(3, stops.length); i++)
                  Positioned(
                    left: positions[i].dx - 17,
                    top: positions[i].dy - 18,
                    child: _MapPin(number: i + 1),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _labelLeft(double width, double pinX, int index) {
    if (index == 1) return math.max(8.0, pinX - width * 0.48).toDouble();
    return pinX + 16;
  }

  double _labelTop(double height, double pinY, int index) {
    if (index == 0) return pinY - 28;
    if (index == 1) return pinY - 13;
    return pinY + 1;
  }
}

class _MapPin extends StatelessWidget {
  final int number;
  const _MapPin({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: _SchedulePalette.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 5, offset: Offset(0, 2))],
      ),
      alignment: Alignment.center,
      child: Text('$number', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }
}

class _MapBackdropPainter extends CustomPainter {
  const _MapBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFFF4F0E8));

    // 지도처럼 보이는 연한 녹지 영역
    final parks = Paint()..color = const Color(0xFFDDEBD8);
    final park1 = Path()
      ..moveTo(0, size.height * 0.05)
      ..lineTo(size.width * 0.22, 0)
      ..lineTo(size.width * 0.36, size.height * 0.20)
      ..lineTo(size.width * 0.25, size.height * 0.42)
      ..lineTo(size.width * 0.08, size.height * 0.36)
      ..close();
    canvas.drawPath(park1, parks);
    final park2 = Path()
      ..moveTo(size.width * 0.30, size.height * 0.53)
      ..lineTo(size.width * 0.60, size.height * 0.48)
      ..lineTo(size.width * 0.70, size.height * 0.70)
      ..lineTo(size.width * 0.53, size.height * 0.95)
      ..lineTo(size.width * 0.28, size.height * 0.82)
      ..close();
    canvas.drawPath(park2, parks);

    // 하천
    final river = Path()
      ..moveTo(size.width * 0.92, -10)
      ..cubicTo(size.width * 0.78, size.height * 0.20, size.width * 0.99, size.height * 0.36, size.width * 0.82, size.height * 0.55)
      ..cubicTo(size.width * 0.72, size.height * 0.69, size.width * 0.92, size.height * 0.83, size.width * 0.82, size.height + 20);
    canvas.drawPath(river, Paint()..color = const Color(0xFFBDE0E7)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.105..strokeCap = StrokeCap.round);
    canvas.drawPath(river, Paint()..color = const Color(0xFFD8EDF0)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.077..strokeCap = StrokeCap.round);

    // 도로와 골목길
    final roadPaint = Paint()..color = const Color(0xFFFFFFFF)..style = PaintingStyle.stroke..strokeWidth = 7;
    final roadEdge = Paint()..color = const Color(0xFFE9E2D7)..style = PaintingStyle.stroke..strokeWidth = 8;
    final roads = <Path>[
      Path()..moveTo(-20, size.height * 0.25)..cubicTo(size.width * .25, size.height * .15, size.width * .62, size.height * .32, size.width + 20, size.height * .25),
      Path()..moveTo(-10, size.height * .62)..cubicTo(size.width * .30, size.height * .51, size.width * .55, size.height * .66, size.width + 20, size.height * .57),
      Path()..moveTo(size.width * .12, -10)..cubicTo(size.width * .25, size.height * .33, size.width * .12, size.height * .68, size.width * .25, size.height + 10),
      Path()..moveTo(size.width * .59, -10)..cubicTo(size.width * .48, size.height * .28, size.width * .66, size.height * .69, size.width * .57, size.height + 10),
      Path()..moveTo(-10, size.height * .86)..lineTo(size.width * .76, size.height * .08),
    ];
    for (final road in roads) {
      canvas.drawPath(road, roadEdge);
      canvas.drawPath(road, roadPaint);
    }

    // 작은 블록을 흩뿌려 지도 질감을 만듭니다.
    final blockPaint = Paint()..color = const Color(0xFFE9E1D5).withOpacity(0.65);
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 7; col++) {
        final x = (col * 0.16 + 0.02) * size.width;
        final y = (row * 0.19 + 0.03) * size.height;
        if (x > size.width * 0.76 && y > size.height * 0.1) continue;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, size.width * .045, size.height * .04), const Radius.circular(3)),
          blockPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TriangleRoutePainter extends CustomPainter {
  final List<Offset> positions;
  const _TriangleRoutePainter({required this.positions});

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.length < 3) return;
    final linePaint = Paint()
      ..color = _SchedulePalette.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawDashedLine(canvas, positions[0], positions[1], linePaint);
    _drawDashedLine(canvas, positions[1], positions[2], linePaint);
    _drawDashedLine(canvas, positions[2], positions[0], linePaint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance == 0) return;
    final direction = delta / distance;
    const dashLength = 7.0;
    const gapLength = 5.0;
    var current = 0.0;
    while (current < distance) {
      final finish = math.min(current + dashLength, distance);
      canvas.drawLine(start + direction * current, start + direction * finish, paint);
      current += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _TriangleRoutePainter oldDelegate) => oldDelegate.positions != positions;
}

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21, color: _SchedulePalette.secondaryText),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: _SchedulePalette.secondaryText))),
      ],
    );
  }
}

class _TimelineStop extends StatelessWidget {
  final _DemoStop stop;
  final int index;
  final bool isLast;
  const _TimelineStop({required this.stop, required this.index, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: _SchedulePalette.primary, shape: BoxShape.circle),
                  child: Text('${index + 1}', style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w900)),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: const Color(0xFFFFC19C), margin: const EdgeInsets.symmetric(vertical: 3)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: SizedBox(
              width: 76,
              height: 76,
              child: _StopThumbnail(stop: stop, compact: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1, bottom: 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stop.timeRange, style: const TextStyle(fontSize: 12, color: _SchedulePalette.secondaryText)),
                  const SizedBox(height: 5),
                  Text(stop.name, style: const TextStyle(fontSize: 15, color: _SchedulePalette.text, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('${stop.category}  ·  ${stop.location}  ·  ${stop.distance}', style: const TextStyle(fontSize: 11, color: _SchedulePalette.secondaryText)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateWithWeekday(DateTime date) {
  const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}';
}

String _formatFullDate(DateTime date) =>
    '${date.year}년 ${date.month}월 ${date.day}일 (${['월', '화', '수', '목', '금', '토', '일'][date.weekday - 1]})';

String _durationLabel(String start, String end) {
  int toMinutes(String value) {
    final parts = value.split(':');
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  var diff = toMinutes(end) - toMinutes(start);
  if (diff < 0) diff += 24 * 60;
  final hours = diff ~/ 60;
  final minutes = diff % 60;
  if (hours > 0 && minutes > 0) return '${hours}시간 ${minutes}분';
  if (hours > 0) return '${hours}시간';
  return '${minutes}분';
}

class _DemoSchedule {
  final String id;
  final String title;
  DateTime date;
  String startTime;
  String endTime;
  final List<String> participants;
  final List<_DemoStop> stops;
  bool isPast;

  _DemoSchedule({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.participants,
    required this.stops,
    this.isPast = false,
  });

  factory _DemoSchedule.fromSavedRecord(SavedScheduleRecord record) {
    return _DemoSchedule(
      id: record.id,
      title: record.title,
      date: record.date,
      startTime: record.startTime,
      endTime: record.endTime,
      participants: record.participants,
      stops: record.stops.map((place) {
        final category = place.category;
        final infoParts = place.info
            .split(RegExp(r'[·•]'))
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList();
        final distanceMatches = infoParts.where((part) =>
            RegExp(r'^\d+(?:\.\d+)?\s*(?:km|m)$', caseSensitive: false).hasMatch(part)).toList();
        final distance = distanceMatches.isNotEmpty ? distanceMatches.first : '';
        final withoutDistance = infoParts.where((part) => part != distance).toList();
        final location = withoutDistance.length >= 2
            ? withoutDistance[1]
            : (withoutDistance.isNotEmpty ? withoutDistance.first : place.info);
        return _DemoStop(
          name: place.name,
          category: category,
          location: location,
          timeRange: place.timeRange,
          distance: distance,
          emoji: _emojiForCategory(category),
          tint: _tintForCategory(category),
        );
      }).toList(),
      isPast: record.isPast,
    );
  }
}

String _emojiForCategory(String category) {
  if (category.contains('카페') || category.contains('베이커리')) return '☕';
  if (category.contains('공원') || category.contains('활동') || category.contains('산책')) return '🌳';
  if (category.contains('식사') || category.contains('음식') || category.contains('한식') || category.contains('레스토랑')) return '🍲';
  return '📍';
}

Color _tintForCategory(String category) {
  if (category.contains('카페') || category.contains('베이커리')) return const Color(0xFFF8D8C2);
  if (category.contains('공원') || category.contains('활동') || category.contains('산책')) return const Color(0xFFDDEFE2);
  return const Color(0xFFFFE4D2);
}

class _DemoStop {
  final String name;
  final String category;
  final String location;
  final String timeRange;
  final String distance;
  final String emoji;
  final Color tint;

  const _DemoStop({
    required this.name,
    required this.category,
    required this.location,
    required this.timeRange,
    required this.distance,
    required this.emoji,
    required this.tint,
  });
}

class _SchedulePalette {
  static const background = Color(0xFFFFFAF7);
  static const text = Color(0xFF20212B);
  static const secondaryText = Color(0xFF7B7D87);
  static const primary = Color(0xFFFF8848);
  static const peach = Color(0xFFFFE9DB);
  static const mint = Color(0xFFDDF4EF);
  static const mintDark = Color(0xFF299D8A);
  static const danger = Color(0xFFEF514D);
  static const divider = Color(0xFFEFEFEB);
}
