import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../models/models.dart';
import '../widgets/primary_button.dart';
import 'situation_screen.dart';

class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  final List<FriendInfo> _friends = [
    const FriendInfo('나', isMe: true),
    const FriendInfo('민진'),
    const FriendInfo('소정'),
  ];

  static const String _inviteLink = 'https://course.app/invite/c3de97';
  static const String _inviteCode = 'c3de97';

  void _copy(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label 복사되었습니다'), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _addFriend() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('친구 추가'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '친구 이름을 입력하세요'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('추가'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() => _friends.add(FriendInfo(name)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '친구 초대',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                '함께할 친구를 초대해보세요!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                '친구가 입력한 취향을 바탕으로\n더 만족스러운 코스를 추천해드려요!',
                style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              _InfoRow(label: '초대 링크', value: _inviteLink, buttonLabel: '링크 복사', onTap: () => _copy('링크가')),
              const SizedBox(height: 10),
              _InfoRow(label: '초대 코드', value: _inviteCode, buttonLabel: '코드 복사', onTap: () => _copy('코드가')),
              const SizedBox(height: 24),
              const Text(
                '참여한 친구',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _friends.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _friends.length) {
                      return InkWell(
                        onTap: _addFriend,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.surface,
                                child: Icon(Icons.add, color: AppColors.textSecondary),
                              ),
                              SizedBox(width: 12),
                              Text('친구 추가', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      );
                    }
                    final friend = _friends[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: friend.isMe ? AppColors.primarySoft : AppColors.mintCardStart,
                            child: Text(
                              friend.name.substring(0, 1),
                              style: TextStyle(
                                color: friend.isMe ? AppColors.primaryDark : const Color(0xFF2E9C8F),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            friend.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: PrimaryButton(
            label: '다음',
            onPressed: () {
              final data = CourseFlowData(mode: FlowMode.friends, friends: _friends);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SituationScreen(data: data, stepIndex: 1, stepTotal: 3),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String buttonLabel;
  final VoidCallback onTap;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(buttonLabel, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
