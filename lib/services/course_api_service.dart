import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import '../models/models.dart';
import '../screens/location_search_screen.dart';
import 'kakao_local_service.dart';
import 'naver_search_service.dart';

class CourseApiServiceLocation {
  static SelectedLocation? selectedLocation;

  static bool get hasLocation =>
      selectedLocation != null;

  static void setLocation(
      SelectedLocation location,
      ) {
    selectedLocation = location;
  }

  static void clear() {
    selectedLocation = null;
  }
}

class CourseApiService {
  final KakaoLocalService _kakao =
  KakaoLocalService();

  final NaverSearchService _naver =
  NaverSearchService();

  /// 이미 추천한 장소 기록 (다시 추천할 때 제외하기 위함)
  static final Set<String> _shownPlaceKeys = {};

  /// 기록이 어떤 조건(위치 + 취향)에 대한 것인지 구분하는 값.
  /// 조건이 바뀌면 기록을 자동으로 비운다.
  static String? _historySignature;

  /// 새 코스 만들기를 시작할 때 호출하면 추천 기록을 초기화한다. (선택)
  static void resetHistory() {
    _shownPlaceKeys.clear();
    _historySignature = null;
  }

  /// [isAlternate]는 기존 호출부와의 호환을 위해 남겨둔 값이다.
  /// 이제 다시 추천 여부와 상관없이 "이미 추천한 장소는 제외"하는 방식으로 동작한다.
  Future<RecommendedCourse?> buildCourse(
      CourseFlowData data, {
        required bool isAlternate,
      }) async {
    if (!dataHasAnyPreference(data)) {
      return null;
    }

    final location =
        CourseApiServiceLocation.selectedLocation;

    if (location == null) {
      debugPrint('선택된 위치가 없습니다.');
      return null;
    }

    try {
      final signature = _signature(data, location);

      if (_historySignature != signature) {
        _shownPlaceKeys.clear();
        _historySignature = signature;
      }

      final foodPlaces =
      await _searchWithFallbacks(
        _foodQueries(data),
        location,
      );

      final cafePlaces =
      await _searchWithFallbacks(
        const ['카페', '커피'],
        location,
      );

      final activityPlaces =
      await _searchWithFallbacks(
        [
          _activityQuery(data),
          '가볼만한곳',
          '공원',
        ].toSet().toList(),
        location,
      );

      if (foodPlaces.isEmpty &&
          cafePlaces.isEmpty &&
          activityPlaces.isEmpty) {
        return null;
      }

      final stops = <CourseStop>[];
      final details = <PlaceDetail>[];

      // 한 코스 안에서 같은 장소가 두 번 나오지 않도록 관리
      final usedInCourse = <String>{};

      void addStop(
          List<KakaoPlace> places, {
            required String category,
            required String timeRange,
            required IconData icon,
            required Color color,
          }) {
        final place =
        _pickPlace(places, usedInCourse);

        if (place == null) {
          return;
        }

        final key = _placeKey(place);
        usedInCourse.add(key);
        _shownPlaceKeys.add(key);

        _addKakaoStop(
          stops,
          details,
          place,
          category: category,
          timeRange: timeRange,
          icon: icon,
          color: color,
        );
      }

      addStop(
        foodPlaces,
        category: '식사',
        timeRange:
        data.situation == '점심 식사' ||
            data.situation == '브런치'
            ? '12:00 ~ 13:30'
            : '18:00 ~ 19:30',
        icon: Icons.restaurant,
        color: const Color(0xFFE8734A),
      );

      addStop(
        cafePlaces,
        category: '카페',
        timeRange: '19:40 ~ 21:00',
        icon: Icons.local_cafe,
        color: const Color(0xFFC98B4A),
      );

      addStop(
        activityPlaces,
        category: '활동',
        timeRange: '21:00 ~ 22:00',
        icon: Icons.park,
        color: const Color(0xFF4A7BC9),
      );

      if (stops.isEmpty) {
        return null;
      }

      return RecommendedCourse(
        headerTitle: data.mode == FlowMode.solo
            ? '지금 취향에 맞는\n실제 장소 코스를 준비했어요!'
            : '${data.namesLabel}을(를) 위한\n실제 장소 코스예요!',
        estimatedDuration:
        stops.length == 3
            ? '4시간'
            : '약 2~4시간',
        stops: stops,
        detailStopIndex: 0,
        detail: details.first,
      );
    } catch (e) {
      debugPrint('Course API 오류: $e');
      return null;
    }
  }

  bool dataHasAnyPreference(
      CourseFlowData data,
      ) {
    return data.foodTypes.isNotEmpty ||
        data.moods.isNotEmpty ||
        data.priorities.isNotEmpty ||
        data.situation != null ||
        data.withWhom.isNotEmpty;
  }

  String _signature(
      CourseFlowData data,
      SelectedLocation location,
      ) {
    return '${location.x},${location.y}'
        '|${data.mode}'
        '|${data.foodTypes}'
        '|${data.moods}'
        '|${data.priorities}'
        '|${data.situation}'
        '|${data.withWhom}';
  }

  String _placeKey(KakaoPlace place) {
    return place.id.isNotEmpty
        ? place.id
        : place.name;
  }

  /// 후보 중에서 "이번 코스에서 안 쓰였고, 아직 추천한 적 없는" 장소를 고른다.
  /// 후보가 모두 이미 추천된 장소라면 기록을 비우고 처음부터 다시 돌린다.
  KakaoPlace? _pickPlace(
      List<KakaoPlace> places,
      Set<String> usedInCourse,
      ) {
    final candidates = places
        .where(
          (p) => !usedInCourse.contains(
        _placeKey(p),
      ),
    )
        .toList();

    if (candidates.isEmpty) {
      return null;
    }

    for (final place in candidates) {
      if (!_shownPlaceKeys.contains(
        _placeKey(place),
      )) {
        return place;
      }
    }

    for (final place in candidates) {
      _shownPlaceKeys.remove(
        _placeKey(place),
      );
    }

    return candidates.first;
  }

  /// 여러 검색어를 순서대로 시도해서 후보를 충분히 모은다.
  /// 첫 검색어 결과가 비어 있어도 다음 검색어로 채워서 코스가 줄어들지 않게 한다.
  Future<List<KakaoPlace>> _searchWithFallbacks(
      List<String> queries,
      SelectedLocation location,
      ) async {
    final merged = <KakaoPlace>[];
    final seen = <String>{};

    for (final query in queries) {
      final places =
      await _searchKakaoWithNaverFallback(
        query,
        location,
      );

      for (final place in places) {
        if (seen.add(_placeKey(place))) {
          merged.add(place);
        }
      }

      if (merged.length >= 8) {
        break;
      }
    }

    return merged;
  }

  Future<List<KakaoPlace>>
  _searchKakaoWithNaverFallback(
      String query,
      SelectedLocation location,
      ) async {
    try {
      final places =
      await _kakao.searchKeyword(
        query,
        size: 15,
        x: location.x,
        y: location.y,
        radius: 2000,
      );

      if (places.isNotEmpty) {
        return places;
      }
    } catch (e) {
      debugPrint(
        'Kakao API 오류 [$query]: $e',
      );
    }

    try {
      final searchQuery =
          '${location.shortAddress} $query';

      final naverPlaces =
      await _naver.searchLocal(
        searchQuery,
        display: 5,
      );

      return naverPlaces
          .map(
            (place) => KakaoPlace(
          id: place.link,
          name: place.title,
          categoryName: place.category,
          addressName: place.address,
          roadAddressName:
          place.roadAddress,
          phone: '',
          placeUrl: place.link,
          x: double.tryParse(
            place.mapx,
          ) ??
              0,
          y: double.tryParse(
            place.mapy,
          ) ??
              0,
          distance: 0,
        ),
      )
          .toList();
    } catch (e) {
      debugPrint(
        'Naver API 오류 [$query]: $e',
      );
      return [];
    }
  }

  List<String> _foodQueries(
      CourseFlowData data,
      ) {
    if (data.foodTypes.isEmpty) {
      return const ['맛집', '음식점'];
    }

    final food = data.foodTypes.first;

    return [
      '$food 맛집',
      food,
      '맛집',
    ].toSet().toList();
  }

  String _activityQuery(
      CourseFlowData data,
      ) {
    if (data.situation == '활동적인 날') {
      return '놀거리';
    }

    if (data.situation == '여가 / 힐링') {
      return '공원';
    }

    if (data.moods.contains('자연 친화적')) {
      return '산책';
    }

    return '가볼만한곳';
  }

  void _addKakaoStop(
      List<CourseStop> stops,
      List<PlaceDetail> details,
      KakaoPlace place, {
        required String category,
        required String timeRange,
        required IconData icon,
        required Color color,
      }) {
    final location =
    place.roadAddressName.isNotEmpty
        ? place.roadAddressName
        : place.addressName;

    final distanceText =
    place.distance > 0
        ? ' · ${(place.distance / 1000).toStringAsFixed(1)}km'
        : '';

    stops.add(
      CourseStop(
        category: category,
        timeRange: timeRange,
        name: place.name,
        info:
        '${place.categoryName.isEmpty ? category : place.categoryName}'
            ' · $location$distanceText',
        icon: icon,
        color: color,
      ),
    );

    details.add(
      PlaceDetail(
        category:
        place.categoryName.isEmpty
            ? category
            : place.categoryName,
        rating: 0,
        reviewCount: 0,
        description:
        '선택한 위치 주변의 실제 장소입니다.',
        hours:
        '영업시간은 장소 상세 페이지에서 확인해주세요.',
        menu:
        '대표 메뉴 정보는 장소 상세 페이지에서 확인해주세요.',
        priceRange:
        '가격 정보는 장소 상세 페이지에서 확인해주세요.',
        facility:
        place.phone.isEmpty
            ? '전화번호 정보 없음'
            : place.phone,
        icon: icon,
        color: color,
      ),
    );
  }
}

extension on SelectedLocation {
  String get shortAddress {
    final parts = address.split(' ');

    if (parts.length >= 3) {
      return '${parts[0]} ${parts[1]} ${parts[2]}';
    }

    return address;
  }
}