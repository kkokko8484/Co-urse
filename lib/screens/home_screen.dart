import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../models/models.dart';
import '../services/course_api_service.dart';
import 'course_screen.dart';
import 'invite_friends_screen.dart';
import 'location_search_screen.dart';
import 'mypage_screen.dart';
import 'schedule_screen.dart';
import 'who_with_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  String _selectedLocation = '어디에서 만날까요?';

  static const List<_TodayPick> _todayPicks = [
    _TodayPick(
      '감성 술집',
      Color(0xFF3A3A4A),
      Icons.wine_bar,
    ),
    _TodayPick(
      '브런치 카페',
      Color(0xFFE8B08A),
      Icons.brunch_dining,
    ),
    _TodayPick(
      '야경 명소',
      Color(0xFF6C5CE7),
      Icons.nightlight_round,
    ),
  ];

  /// 장소 검색 화면을 열고, 장소를 선택하면 true 반환
  Future<bool> _selectLocation() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LocationSearchScreen(),
      ),
    );

    if (!mounted) return false;

    if (result is SelectedLocation) {
      setState(() {
        _selectedLocation = result.displayName;
      });

      CourseApiServiceLocation.setLocation(result);
      return true;
    }

    return false;
  }

  /// 상황에 맞는 코스 추천받기
  Future<void> _startCourse() async {
    if (!CourseApiServiceLocation.hasLocation) {
      final selected = await _selectLocation();

      if (!selected || !mounted) return;
    }

    final data = CourseFlowData(
      mode: FlowMode.solo,
    );

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WhoWithScreen(data: data),
      ),
    );
  }

  /// 친구들과 함께 코스 만들기
  Future<void> _startFriendsCourse() async {
    if (!CourseApiServiceLocation.hasLocation) {
      final selected = await _selectLocation();

      if (!selected || !mounted) return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const InviteFriendsScreen(),
      ),
    );
  }

  /// 홈 화면 콘텐츠
  Widget _buildHomeBody() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // 위치 선택
            GestureDetector(
              onTap: _selectLocation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedLocation,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              '어떤 코스를 만들까요?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              '상황과 취향에 딱 맞는\n최적의 코스를 추천해드릴게요!',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 20),

            _EntryCard(
              title: '친구들과 함께\n코스 만들기',
              icon: Icons.groups_rounded,
              gradientColors: const [
                AppColors.peachCardStart,
                AppColors.peachCardEnd,
              ],
              iconColor: const Color(0xFFD97B4C),
              onTap: _startFriendsCourse,
            ),

            const SizedBox(height: 14),

            _EntryCard(
              title: '상황에 맞는\n코스 추천받기',
              icon: Icons.map_rounded,
              gradientColors: const [
                AppColors.mintCardStart,
                AppColors.mintCardEnd,
              ],
              iconColor: const Color(0xFF2E9C8F),
              onTap: _startCourse,
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '오늘의 추천',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '더 많은 추천 보기 >',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _todayPicks.length,
                separatorBuilder: (_, __) =>
                const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final pick = _todayPicks[index];

                  return Container(
                    width: 96,
                    decoration: BoxDecoration(
                      color: pick.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          pick.icon,
                          color: Colors.white,
                          size: 26,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pick.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 하단 네비게이션으로 메인 화면 전환
  void _onNavigationTap(int index) {
    if (_navIndex == index) return;

    setState(() {
      _navIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // 메인 화면 4개를 전환합니다.
      // IndexedStack을 사용하므로 탭을 바꿔도 기존 화면 상태를 유지합니다.
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildHomeBody(),
          const CourseScreen(),
          const ScheduleScreen(),
          const MyPageScreen(),
        ],
      ),

      // 메인 화면 4개에서만 표시되는 공통 하단 메뉴
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onNavigationTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: '코스',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: '일정',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '마이',
          ),
        ],
      ),
    );
  }
}

class _TodayPick {
  final String label;
  final Color color;
  final IconData icon;

  const _TodayPick(
      this.label,
      this.color,
      this.icon,
      );
}

class _EntryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final Color iconColor;
  final VoidCallback onTap;

  const _EntryCard({
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 108,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                height: 1.3,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}