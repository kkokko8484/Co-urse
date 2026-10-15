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
      title: '북촌 한옥마을에서 즐기는\n감성 데이트 코스',
      tag: '데이트 코스',
      location: '서울 종로구',
      imageUrl:
          'https://commons.wikimedia.org/wiki/Special:FilePath/Bukchon%20Hanok%20Village%2001.jpg?width=900',
    ),
    _TodayPick(
      title: '분위기 좋은 카페에서\n여유로운 하루',
      tag: '맛집 코스',
      location: '서울 마포구',
      imageUrl:
          'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=900&q=85',
    ),
    _TodayPick(
      title: '도심 속 풍경을 즐기는\n힐링 코스',
      tag: '힐링 코스',
      location: '서울 영등포구',
      imageUrl:
          'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?auto=format&fit=crop&w=900&q=85',
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

// 친구들과 함께 코스 만들기
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

// 상황에 맞는 코스 추천받기
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

            const SizedBox(height: 28),

// 오늘의 추천 제목
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '오늘의 추천',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _navIndex = 1;
                    });
                  },
                  child: const Text(
                    '더 많은 추천 보기 >',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

// 가로형 사진 추천 카드
            SizedBox(
              height: 340,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _todayPicks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final pick = _todayPicks[index];

                  return SizedBox(
                    width: 270,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
// 추천 장소 사진
                          Image.network(
                            pick.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }

                              return Container(
                                color: const Color(0xFFEAEAEA),
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFFEAEAEA),
                                alignment: Alignment.center,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 36,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '이미지를 불러올 수 없어요',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

// 사진 위쪽은 밝고 아래쪽은 어둡게 처리
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x11000000),
                                  Color(0x00000000),
                                  Color(0xDD000000),
                                ],
                                stops: [0.0, 0.35, 1.0],
                              ),
                            ),
                          ),

// 왼쪽 위 테마 태그
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                pick.tag,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),

// 아래쪽 제목과 위치
                          Positioned(
                            left: 18,
                            right: 18,
                            bottom: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pick.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    height: 1.35,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      pick.location,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

// 페이지 표시 점
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _todayPicks.length,
                (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == 0 ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
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

// IndexedStack을 사용해 탭을 바꿔도 기존 화면 상태 유지
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildHomeBody(),
          const CourseScreen(),
          const ScheduleScreen(),
          const MyPageScreen(),
        ],
      ),

// 공통 하단 메뉴
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

/// 오늘의 추천 카드 데이터
class _TodayPick {
  final String title;
  final String tag;
  final String location;
  final String imageUrl;

  const _TodayPick({
    required this.title,
    required this.tag,
    required this.location,
    required this.imageUrl,
  });
}

/// 홈 화면의 코스 시작 카드
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
