import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../services/course_api_service.dart';
import '../services/kakao_local_service.dart';
import 'location_search_screen.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final KakaoLocalService _kakao = KakaoLocalService();
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categories = [
    '전체',
    '맛집',
    '카페',
    '관광지',
    '공원·자연',
  ];

  static const List<_ThemeItem> _themes = [
    _ThemeItem(
      label: '맛집 투어',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFFE7D7),
      query: '맛집',
    ),
    _ThemeItem(
      label: '카페 투어',
      icon: Icons.local_cafe_rounded,
      color: Color(0xFFF2E8D9),
      query: '카페',
    ),
    _ThemeItem(
      label: '자연 힐링',
      icon: Icons.park_rounded,
      color: Color(0xFFDDF0E6),
      query: '공원',
    ),
    _ThemeItem(
      label: '도시 산책',
      icon: Icons.location_city_rounded,
      color: Color(0xFFE1EAF8),
      query: '관광지',
    ),
  ];

  static const List<String> _photoUrls = [
    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=700',
    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=700',
    'https://images.unsplash.com/photo-1493854330552-0e8f8e7f4f4f?w=700',
    'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=700',
  ];

  String _selectedCategory = '전체';
  String _selectedTheme = '';
  String _searchText = '';

  List<KakaoPlace> _places = [];
  bool _loading = false;
  String? _error;

  // 현재 화면에서만 유지되는 북마크
  final Set<String> _bookmarkedIds = {};

  SelectedLocation? get _location => CourseApiServiceLocation.selectedLocation;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _queryForCategory(String category) {
    switch (category) {
      case '맛집':
        return '맛집';
      case '카페':
        return '카페';
      case '관광지':
        return '관광지';
      case '공원·자연':
        return '공원';
      default:
        return '';
    }
  }

  // 약속 장소 주변 검색
  Future<void> _loadPlaces({String? query}) async {
    final location = _location;

    if (location == null) {
      if (!mounted) return;

      setState(() {
        _places = [];
        _loading = false;
        _error = null;
      });
      return;
    }

    final keyword = query ?? _searchText.trim();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<KakaoPlace> results = [];

      if (keyword.isNotEmpty) {
        results = await _kakao.searchKeyword(
          keyword,
          size: 15,
          x: location.x,
          y: location.y,
          radius: 5000,
        );
      } else if (_selectedCategory == '전체') {
        final groups = await Future.wait([
          _kakao.searchKeyword(
            '맛집',
            size: 5,
            x: location.x,
            y: location.y,
            radius: 5000,
          ),
          _kakao.searchKeyword(
            '카페',
            size: 5,
            x: location.x,
            y: location.y,
            radius: 5000,
          ),
          _kakao.searchKeyword(
            '관광지',
            size: 5,
            x: location.x,
            y: location.y,
            radius: 5000,
          ),
          _kakao.searchKeyword(
            '공원',
            size: 5,
            x: location.x,
            y: location.y,
            radius: 5000,
          ),
        ]);

        final unique = <String, KakaoPlace>{};

        for (final group in groups) {
          for (final place in group) {
            unique.putIfAbsent(place.id, () => place);
          }
        }

        results = unique.values.toList();
      } else {
        results = await _kakao.searchKeyword(
          _queryForCategory(_selectedCategory),
          size: 15,
          x: location.x,
          y: location.y,
          radius: 5000,
        );
      }

      results.sort((a, b) {
        if (a.distance == 0 && b.distance != 0) return 1;
        if (b.distance == 0 && a.distance != 0) return -1;
        return a.distance.compareTo(b.distance);
      });

      if (!mounted) return;

      setState(() {
        _places = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _places = [];
        _loading = false;
        _error = '주변 장소를 불러오지 못했어요.\n'
            '네트워크와 카카오 API 키를 확인해 주세요.';
      });
    }
  }

  // 약속 장소 변경
  Future<void> _selectLocation() async {
    final result = await Navigator.of(context).push<SelectedLocation>(
      MaterialPageRoute(
        builder: (_) => const LocationSearchScreen(),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      CourseApiServiceLocation.setLocation(result);

      setState(() {
        _searchText = '';
        _searchController.clear();
      });

      await _loadPlaces();
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _selectedTheme = '';
      _searchText = '';
      _searchController.clear();
    });

    _loadPlaces();
  }

  void _onSearchSubmitted(String value) {
    final keyword = value.trim();

    setState(() {
      _searchText = keyword;
      _selectedTheme = '';
    });

    _loadPlaces(query: keyword.isEmpty ? null : keyword);
  }

  void _onThemeSelected(_ThemeItem item) {
    setState(() {
      _selectedTheme = item.label;
      _selectedCategory = item.query == '공원' ? '공원·자연' : item.query;
      _searchText = item.query;
      _searchController.text = item.query;
    });

    _loadPlaces(query: item.query);
  }

  String _categoryLabel(KakaoPlace place) {
    if (place.categoryName.isEmpty) return '주변 장소';

    final parts = place.categoryName.split('>');
    return parts.last.trim();
  }

  String _addressLabel(KakaoPlace place) {
    final address = place.roadAddressName.isNotEmpty
        ? place.roadAddressName
        : place.addressName;

    final parts = address.split(' ');

    if (parts.length >= 3) {
      return '${parts[0]} ${parts[1]} ${parts[2]}';
    }

    return address;
  }

  String _distanceLabel(KakaoPlace place) {
    if (place.distance <= 0) return '';

    if (place.distance < 1000) {
      return '${place.distance}m';
    }

    return '${(place.distance / 1000).toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    final location = _location;

    return Scaffold(
      backgroundColor: AppColors.background,

      // 상단에는 제목만 표시
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '코스',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // 하단 네비게이션 바는 여기서 별도로 만들지 않음
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _loadPlaces(),
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHero(location),
                    const SizedBox(height: 14),
                    _buildSearchBox(),
                    const SizedBox(height: 12),
                    _buildCategoryChips(),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            location == null
                                ? '약속 장소 주변 인기 장소'
                                : '${location.displayName} 주변 인기 장소',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _selectLocation,
                          child: const Text(
                            '장소 변경  ›',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (location == null)
                      _buildNoLocation()
                    else if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (_error != null)
                      _buildError()
                    else if (_places.isEmpty)
                      _buildEmpty()
                    else
                      ..._places.take(8).toList().asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildPlaceCard(
                                entry.value,
                                entry.key,
                              ),
                            ),
                          ),
                    const SizedBox(height: 18),
                    const Text(
                      '지금 많이 찾는 테마',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _themes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          return _buildThemeCard(_themes[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildNearbyHint(location),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 상단 배너
  Widget _buildHero(SelectedLocation? location) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 172,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=1200&auto=format&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF77B7DB),
                        Color(0xFF2C769B),
                      ],
                    ),
                  ),
                );
              },
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xAA123D5A),
                    Color(0x22123D5A),
                    Color(0x66304B50),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '약속 장소 근처에는?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    location == null
                        ? '주변 인기 장소를\n둘러보세요'
                        : '${location.displayName} 주변\n인기 장소를 둘러보세요',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    location == null
                        ? '약속 장소를 먼저 선택해 주세요'
                        : '맛집, 카페, 관광지, 공원까지!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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

  // 검색창
  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: _onSearchSubmitted,
      decoration: InputDecoration(
        hintText: '맛집, 카페, 관광지, 공원 검색',
        hintStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => _onSearchSubmitted(_searchController.text),
        ),
        filled: true,
        fillColor: const Color(0xFFF7F7F8),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // 카테고리
  Widget _buildCategoryChips() {
    final icons = <String, IconData>{
      '전체': Icons.grid_view_rounded,
      '맛집': Icons.restaurant_rounded,
      '카페': Icons.local_cafe_rounded,
      '관광지': Icons.photo_camera_outlined,
      '공원·자연': Icons.eco_outlined,
    };

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = _selectedCategory == category;

          return InkWell(
            onTap: () => _onCategorySelected(category),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: category == '공원·자연' ? 78 : 66,
              padding: const EdgeInsets.symmetric(
                vertical: 9,
                horizontal: 4,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : const Color(0xFFF7F7F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icons[category],
                    size: 21,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 장소 카드
  Widget _buildPlaceCard(KakaoPlace place, int index) {
    final isBookmarked = _bookmarkedIds.contains(place.id);
    final photoUrl = _photoUrls[index % _photoUrls.length];
    final distance = _distanceLabel(place);

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF0F0F1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              width: 112,
              height: 86,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: const Color(0xFFE7EEF2),
                        child: const Icon(
                          Icons.photo_outlined,
                          size: 30,
                          color: AppColors.textTertiary,
                        ),
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC65C),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_addressLabel(place)} · ${_categoryLabel(place)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (distance.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.near_me_outlined,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '약속 장소에서 $distance',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: isBookmarked ? '저장 취소' : '장소 저장',
            onPressed: () {
              setState(() {
                if (isBookmarked) {
                  _bookmarkedIds.remove(place.id);
                } else {
                  _bookmarkedIds.add(place.id);
                }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isBookmarked ? '저장을 취소했어요.' : '장소를 저장했어요.',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: Icon(
              isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isBookmarked ? AppColors.primary : AppColors.textSecondary,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  // 테마 카드
  Widget _buildThemeCard(_ThemeItem item) {
    final selected = _selectedTheme == item.label;

    return InkWell(
      onTap: () => _onThemeSelected(item),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 92,
        decoration: BoxDecoration(
          color: item.color,
          borderRadius: BorderRadius.circular(15),
          border: selected
              ? Border.all(
                  color: AppColors.primary,
                  width: 2,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 25,
              color: const Color(0xFF4D5A62),
            ),
            const SizedBox(height: 7),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF35404A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 약속 장소가 없는 경우
  Widget _buildNoLocation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            '약속 장소를 먼저 선택해 주세요',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '선택한 장소를 기준으로 주변 장소를 찾아드릴게요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: _selectLocation,
            child: const Text('약속 장소 선택하기'),
          ),
        ],
      ),
    );
  }

  // 오류 메시지
  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: AppColors.primary,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _loadPlaces(),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  // 검색 결과가 없는 경우
  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 30,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: 8),
          Text(
            '주변 장소를 찾지 못했어요.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            '다른 카테고리를 선택하거나 검색어를 바꿔보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // 약속 장소 변경 안내
  Widget _buildNearbyHint(SelectedLocation? location) {
    return InkWell(
      onTap: _selectLocation,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F5FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.map_rounded,
              color: AppColors.primary,
              size: 27,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location == null ? '어디에서 만날 예정인가요?' : '다른 약속 장소 주변도 둘러볼까요?',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    '약속 장소를 바꾸면 주변 장소도 새로 찾아요.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeItem {
  final String label;
  final IconData icon;
  final Color color;
  final String query;

  const _ThemeItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.query,
  });
}
