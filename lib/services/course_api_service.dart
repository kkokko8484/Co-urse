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
      final foodQuery =
      _foodQuery(data, isAlternate);

      final foodPlaces =
      await _searchKakaoWithNaverFallback(
        foodQuery,
        location,
      );

      final cafePlaces =
      await _searchKakaoWithNaverFallback(
        '카페',
        location,
      );

      final activityPlaces =
      await _searchKakaoWithNaverFallback(
        _activityQuery(data),
        location,
      );

      if (foodPlaces.isEmpty &&
          cafePlaces.isEmpty &&
          activityPlaces.isEmpty) {
        return null;
      }

      final stops = <CourseStop>[];
      final details = <PlaceDetail>[];

      _addKakaoStop(
        stops,
        details,
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

      _addKakaoStop(
        stops,
        details,
        cafePlaces,
        category: '카페',
        timeRange: '19:40 ~ 21:00',
        icon: Icons.local_cafe,
        color: const Color(0xFFC98B4A),
      );

      _addKakaoStop(
        stops,
        details,
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

  Future<List<KakaoPlace>>
  _searchKakaoWithNaverFallback(
      String query,
      SelectedLocation location,
      ) async {
    try {
      final places =
      await _kakao.searchKeyword(
        query,
        size: 10,
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

  String _foodQuery(
      CourseFlowData data,
      bool isAlternate,
      ) {
    final food = data.foodTypes.isNotEmpty
        ? data.foodTypes.first
        : '맛집';

    final suffix =
    isAlternate
        ? ' 추천 맛집'
        : ' 맛집';

    return '$food$suffix';
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
      List<KakaoPlace> places, {
        required String category,
        required String timeRange,
        required IconData icon,
        required Color color,
      }) {
    if (places.isEmpty) {
      return;
    }

    final place = places.first;

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