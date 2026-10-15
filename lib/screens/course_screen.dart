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
      label: '데이트 코스',
      subtitle: '식사부터 카페, 산책까지',
      icon: Icons.favorite_rounded,
      color: Color(0xFFFFE3E3),
      steps: [
        _ThemeStep(label: '식사하기', query: '맛집'),
        _ThemeStep(label: '분위기 좋은 카페', query: '카페'),
        _ThemeStep(label: '함께 산책하기', query: '공원'),
      ],
    ),
    _ThemeItem(
      label: '친구와 놀기',
      subtitle: '맛집과 주변 놀거리',
      icon: Icons.groups_rounded,
      color: Color(0xFFFFE9D7),
      steps: [
        _ThemeStep(label: '같이 식사하기', query: '맛집'),
        _ThemeStep(label: '가볼 만한 곳', query: '관광지'),
        _ThemeStep(label: '카페에서 쉬기', query: '카페'),
      ],
    ),
    _ThemeItem(
      label: '가족 나들이',
      subtitle: '식사와 볼거리 중심',
      icon: Icons.family_restroom_rounded,
      color: Color(0xFFE1EAF8),
      steps: [
        _ThemeStep(label: '가족 식사', query: '맛집'),
        _ThemeStep(label: '주변 명소', query: '관광지'),
        _ThemeStep(label: '공원·자연', query: '공원'),
      ],
    ),
    _ThemeItem(
      label: '힐링 코스',
      subtitle: '자연 속에서 여유롭게',
      icon: Icons.spa_rounded,
      color: Color(0xFFDDF0E6),
      steps: [
        _ThemeStep(label: '자연·공원', query: '공원'),
        _ThemeStep(label: '조용한 카페', query: '카페'),
      ],
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

  final Set<String> _bookmarkedIds = {};

  SelectedLocation? get _location =>
      CourseApiServiceLocation.selectedLocation;

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

  Future<void> _onThemeSelected(_ThemeItem item) async {
    final location = _location;

    if (location == null) {
      await _selectLocation();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ThemeCourseScreen(
          theme: item,
          location: location,
          kakao: _kakao,
          distanceLabel: _distanceLabel,
        ),
      ),
    );
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
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _loadPlaces(),
          child: CustomScrollView(
            keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
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
                    const SizedBox(height: 5),
                    const Text(
                      '어떤 약속을 하고 싶은지 선택해 보세요.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 112,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _themes.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(width: 10),
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
                color: selected
                    ? AppColors.primary
                    : const Color(0xFFF7F7F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icons[category],
                    size: 21,
                    color:
                    selected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                      color:
                      selected ? Colors.white : AppColors.textSecondary,
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
              color: isBookmarked
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(_ThemeItem item) {
    return InkWell(
      onTap: () => _onThemeSelected(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 24,
              color: const Color(0xFF4D5A62),
            ),
            const SizedBox(height: 7),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF35404A),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF58636B),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                    location == null
                        ? '어디에서 만날 예정인가요?'
                        : '다른 약속 장소 주변도 둘러볼까요?',
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
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_ThemeStep> steps;

  const _ThemeItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.steps,
  });
}

class _ThemeStep {
  final String label;
  final String query;

  const _ThemeStep({
    required this.label,
    required this.query,
  });
}

class _ThemeCourseScreen extends StatefulWidget {
  final _ThemeItem theme;
  final SelectedLocation location;
  final KakaoLocalService kakao;
  final String Function(KakaoPlace) distanceLabel;

  const _ThemeCourseScreen({
    required this.theme,
    required this.location,
    required this.kakao,
    required this.distanceLabel,
  });

  @override
  State<_ThemeCourseScreen> createState() => _ThemeCourseScreenState();
}

class _ThemeCourseScreenState extends State<_ThemeCourseScreen> {
  late Future<List<List<KakaoPlace>>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _loadThemePlaces();
  }

  Future<List<List<KakaoPlace>>> _loadThemePlaces() async {
    final location = widget.location;

    final futures = widget.theme.steps.map((step) {
      return widget.kakao.searchKeyword(
        step.query,
        size: 5,
        x: location.x,
        y: location.y,
        radius: 5000,
      );
    }).toList();

    return Future.wait(futures);
  }

  String _addressLabel(KakaoPlace place) {
    final address = place.roadAddressName.isNotEmpty
        ? place.roadAddressName
        : place.addressName;

    final parts = address.split(' ');

    return parts.length >= 3
        ? '${parts[0]} ${parts[1]} ${parts[2]}'
        : address;
  }

  String _categoryLabel(KakaoPlace place) {
    if (place.categoryName.isEmpty) return '주변 장소';

    return place.categoryName.split('>').last.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          theme.label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: FutureBuilder<List<List<KakaoPlace>>>(
        future: _resultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 36),
                    const SizedBox(height: 12),
                    const Text('추천 장소를 불러오지 못했어요.'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _resultsFuture = _loadThemePlaces();
                        });
                      },
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            );
          }

          final groups = snapshot.data ?? [];

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              final future = _loadThemePlaces();
              setState(() {
                _resultsFuture = future;
              });
              await future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.color,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Icon(
                          theme.icon,
                          size: 29,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              theme.label,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              theme.subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.location.displayName} 주변 장소',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  '이렇게 둘러보세요',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '각 단계에서 마음에 드는 장소를 골라보세요.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(theme.steps.length, (index) {
                  final step = theme.steps[index];

                  final places = index < groups.length
                      ? groups[index]
                      : <KakaoPlace>[];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                step.label,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (places.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              '주변에서 추천할 장소를 찾지 못했어요.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        else
                          ...places.take(3).map((place) {
                            final distance =
                            widget.distanceLabel(place);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFF0F0F1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: theme.color,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Icon(
                                      step.query == '맛집'
                                          ? Icons.restaurant_rounded
                                          : step.query == '카페'
                                          ? Icons.local_cafe_rounded
                                          : step.query == '공원'
                                          ? Icons.park_rounded
                                          : Icons.place_rounded,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_categoryLabel(place)} · '
                                              '${_addressLabel(place)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        if (distance.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '약속 장소에서 $distance',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  );
                }),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F5FA),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '이 화면은 약속 목적에 맞춰 장소 종류를 단계별로 추천해요. '
                              '각 장소를 실제 이동 경로로 연결하는 기능은 별도로 추가할 수 있어요.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}