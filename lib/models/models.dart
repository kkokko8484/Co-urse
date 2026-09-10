import 'package:flutter/material.dart';

/// 코스 생성 모드: 혼자(상황 기반) / 친구들과 함께
enum FlowMode { solo, friends }

/// 친구 초대 목업 데이터
class FriendInfo {
  final String name;
  final bool isMe;
  const FriendInfo(this.name, {this.isMe = false});
}

/// 사용자가 취향 선택 단계에서 누적하는 데이터
class CourseFlowData {
  final FlowMode mode;
  final List<FriendInfo> friends;

  final List<String> withWhom = [];
  String? situation;
  final List<String> foodTypes = [];
  final List<String> moods = [];
  final List<String> priorities = [];
  String? budget;
  final List<String> avoidFactors = [];

  CourseFlowData({required this.mode, List<FriendInfo>? friends})
      : friends = friends ?? [];

  /// 대표 이름들 (추천 코스 헤더에 사용)
  String get namesLabel {
    if (mode == FlowMode.solo) return '나';
    final others = friends.where((f) => !f.isMe).map((f) => f.name).toList();
    return [...others, '나'].join(', ');
  }
}

/// 코스를 구성하는 한 개의 장소(식사/카페/활동 등)
class CourseStop {
  final String category; // 식사 / 카페 / 활동
  final String timeRange; // 18:00 ~ 19:30
  final String name;
  final String info; // 한식 · 사직동 · 1km
  final IconData icon;
  final Color color;

  const CourseStop({
    required this.category,
    required this.timeRange,
    required this.name,
    required this.info,
    required this.icon,
    required this.color,
  });
}

/// 코스 상세 페이지에 쓰이는 추가 정보
class PlaceDetail {
  final String category;
  final double rating;
  final int reviewCount;
  final String description;
  final String hours;
  final String menu;
  final String priceRange;
  final String facility;
  final IconData icon;
  final Color color;

  const PlaceDetail({
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.description,
    required this.hours,
    required this.menu,
    required this.priceRange,
    required this.facility,
    required this.icon,
    required this.color,
  });
}

/// 하나의 추천 코스 (식사 → 카페 → 활동)
class RecommendedCourse {
  final String headerTitle;
  final List<CourseStop> stops;
  final String estimatedDuration;
  final PlaceDetail detail; // 코스 상세 보기에 쓰이는 대표 장소 상세정보
  final int detailStopIndex; // detail 이 어느 stop 에 대응하는지

  const RecommendedCourse({
    required this.headerTitle,
    required this.stops,
    required this.estimatedDuration,
    required this.detail,
    this.detailStopIndex = 0,
  });
}
