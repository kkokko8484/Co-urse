import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../models/models.dart';
import '../services/saved_schedule_store.dart';

/// 저장된 코스 일정을 보여주는 화면 (하단 "코스" 탭)
class SavedCourseScreen extends StatelessWidget {
  const SavedCourseScreen({super.key});

  static const List<String> _weekdays = [
    '월', '화', '수', '목', '금', '토', '일',
  ];

  static String formatDate(DateTime d) {
    return '${d.year}년 ${d.month}월 ${d.day}일 (${_weekdays[d.weekday - 1]})';
  }

  Future<void> _confirmDelete(
      BuildContext context,
      SavedSchedule schedule,
      ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('일정을 삭제할까요?'),
        content: const Text('삭제하면 저장된 코스 일정이 사라져요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '삭제',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final store = SavedScheduleStore.instance;

    store.remove(schedule.id);

    // 마지막 일정을 지우면 메인 화면으로 돌아간다.
    if (store.isEmpty) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('저장된 코스 일정이 없어요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = SavedScheduleStore.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '내 일정',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final items = store.items;

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '저장한 코스 일정',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '총 ${items.length}개의 일정이 저장되어 있어요.',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                }

                final schedule = items[i - 1];

                return _ScheduleCard(
                  schedule: schedule,
                  onDelete: () => _confirmDelete(context, schedule),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final SavedSchedule schedule;
  final VoidCallback onDelete;

  const _ScheduleCard({
    required this.schedule,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final course = schedule.course;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Text(
            '${SavedCourseScreen.formatDate(schedule.date)}  '
                '${schedule.startTime} ~ ${schedule.endTime}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < course.stops.length; i++)
                _StopTile(
                  index: i,
                  stop: course.stops[i],
                  isLast: i == course.stops.length - 1,
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 15,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '예상 소요시간 ${course.estimatedDuration}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                      label: const Text(
                        '삭제',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StopTile extends StatelessWidget {
  final int index;
  final CourseStop stop;
  final bool isLast;

  const _StopTile({
    required this.index,
    required this.stop,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.chipBorder),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stop.category}  ${stop.timeRange}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.chipBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: stop.color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(stop.icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stop.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stop.info,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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