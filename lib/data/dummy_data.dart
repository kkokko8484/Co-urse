import 'package:flutter/material.dart';
import '../models/models.dart';

/// 취향 선택 단계에서 사용하는 선택지 목록
class OptionSets {
  OptionSets._();

  static const List<String> withWhom = [
    '연인', '가족', '친구',
    '회사 동료', '비즈니스 미팅', '혼자',
    '부모님', '아이와 함께', '소개팅',
    '반려동물과', '단체 모임', '기타',
  ];

  static const List<String> situations = [
    '기념일', '생일', '데이트',
    '점심 식사', '저녁 식사', '브런치',
    '가벼운 모임', '특별한 날', '일상 데이트',
    '여가 / 힐링', '활동적인 날', '기타',
  ];

  static const List<String> foodTypes = [
    '한식', '양식', '일식', '중식',
    '디저트', '분식', '일식', '샐러드',
  ];

  static const List<String> moods = [
    '조용한', '활기찬', '아늑한', '이국적인',
    '고급스러운', '캐주얼한', '힙한', '자연 친화적',
  ];

  static const List<String> priorities = [
    '맛집', '분위기', '가성비', '프라이버시',
    '부/동행', '특별한 경험', '접근성',
  ];

  static const List<String> budgets = [
    '~1만원', '1~2만원', '3~5만원', '5만원~',
  ];

  static const List<String> avoidFactors = [
    '웨이팅이 긴 곳',
    '걷는 거리가 먼 곳',
    '시끄러운 곳',
    '술자리',
    '너무 비싼 곳',
    '사람이 많은 곳',
  ];
}

/// 혼자(상황 기반) 흐름 - 기본 추천 코스
final RecommendedCourse soloPrimaryCourse = RecommendedCourse(
  headerTitle: '지금 상황에 딱 맞는\n코스를 준비했어요!',
  estimatedDuration: '4시간',
  stops: const [
    CourseStop(
      category: '식사',
      timeRange: '18:00 ~ 19:30',
      name: '생선구이소반',
      info: '한식 · 사직동 · 1km',
      icon: Icons.restaurant,
      color: Color(0xFFE8734A),
    ),
    CourseStop(
      category: '카페',
      timeRange: '19:40 ~ 21:00',
      name: '본지르트 베이커리 서촌',
      info: '카페 · 필운동 · 1km',
      icon: Icons.local_cafe,
      color: Color(0xFFC98B4A),
    ),
    CourseStop(
      category: '활동',
      timeRange: '21:00 ~ 22:00',
      name: '광화문광장',
      info: '광장 · 종로구 · 1.5km',
      icon: Icons.park,
      color: Color(0xFF4A7BC9),
    ),
  ],
  detailStopIndex: 0,
  detail: PlaceDetail(
    category: '한식 · 사직동',
    rating: 4.7,
    reviewCount: 373,
    description: '따뜻하고 편안한 분위기의 한식당이에요.\n정갈한 생선구이와 다양한 반찬을 부담 없이 즐길 수 있어요.',
    hours: '매일 11:00 ~ 20:30',
    menu: '고등어구이, 물회',
    priceRange: '1인 15,000원 ~ 20,000원',
    facility: '화장실',
    icon: Icons.restaurant,
    color: Color(0xFFE8734A),
  ),
);

/// 혼자(상황 기반) 흐름 - 다시 추천했을 때(아쉬우셨나요) 코스
final RecommendedCourse soloAltCourse = RecommendedCourse(
  headerTitle: '아쉬우셨나요?\n다른 코스를 준비했어요',
  estimatedDuration: '4시간',
  stops: const [
    CourseStop(
      category: '식사',
      timeRange: '18:00 ~ 19:30',
      name: '중앙해장 광화문점',
      info: '한식 · 종로구 · 2km',
      icon: Icons.restaurant,
      color: Color(0xFFE8734A),
    ),
    CourseStop(
      category: '카페',
      timeRange: '19:40 ~ 21:00',
      name: '개성스카페',
      info: '카페 · 종로구 · 0.5km',
      icon: Icons.local_cafe,
      color: Color(0xFFC98B4A),
    ),
    CourseStop(
      category: '활동',
      timeRange: '21:00 ~ 22:00',
      name: '청계천',
      info: '공원 · 종로구 · 1.7km',
      icon: Icons.park,
      color: Color(0xFF4A7BC9),
    ),
  ],
  detailStopIndex: 0,
  detail: PlaceDetail(
    category: '한식 · 종로구',
    rating: 4.5,
    reviewCount: 201,
    description: '깔끔하고 시원한 국물이 일품인 해장 전문점이에요.\n부담 없는 가격에 든든한 한끼를 즐길 수 있어요.',
    hours: '매일 09:00 ~ 22:00',
    menu: '해장국, 선지국',
    priceRange: '1인 9,000원 ~ 13,000원',
    facility: '화장실, 주차',
    icon: Icons.restaurant,
    color: Color(0xFFE8734A),
  ),
);

/// 친구들과 함께 흐름 - 기본 추천 코스
RecommendedCourse friendsPrimaryCourse(String namesLabel) => RecommendedCourse(
      headerTitle: '$namesLabel을(를) 위한\n맞춤 코스예요!',
      estimatedDuration: '5시간',
      stops: const [
        CourseStop(
          category: '식사',
          timeRange: '12:00 ~ 13:30',
          name: '광명한정식',
          info: '한식 · 광명시 · 3.5km',
          icon: Icons.restaurant,
          color: Color(0xFFE8734A),
        ),
        CourseStop(
          category: '카페',
          timeRange: '14:00 ~ 15:30',
          name: '힛더 스팟',
          info: '카페 · 가산동 · 4.5km',
          icon: Icons.local_cafe,
          color: Color(0xFFC98B4A),
        ),
        CourseStop(
          category: '활동',
          timeRange: '16:00 ~ 17:00',
          name: '시민공원',
          info: '공원 · 광명시 · 4.9km',
          icon: Icons.park,
          color: Color(0xFF4A7BC9),
        ),
      ],
      detailStopIndex: 1,
      detail: const PlaceDetail(
        category: '카페 · 가산동',
        rating: 4.5,
        reviewCount: 124,
        description: '따뜻하고 편안한 분위기의 감성카페예요.\n다양한 디저트와 커피를 부담 없이 즐길 수 있어요.',
        hours: '매일 10:00 ~ 22:00',
        menu: '소세지 빵, 슈크림 빵',
        priceRange: '1인 5,000원 ~ 10,000원',
        facility: '주차, 와이파이, 화장실',
        icon: Icons.local_cafe,
        color: Color(0xFFC98B4A),
      ),
    );

/// 친구들과 함께 흐름 - 다시 추천했을 때(아쉬우셨나요) 코스
RecommendedCourse friendsAltCourse(String namesLabel) => RecommendedCourse(
      headerTitle: '아쉬우셨나요?\n다른 분위기의 코스예요',
      estimatedDuration: '6시간',
      stops: const [
        CourseStop(
          category: '식사',
          timeRange: '12:00 ~ 13:30',
          name: '라라코스트',
          info: '양식 · 철산동 · 1.2km',
          icon: Icons.restaurant,
          color: Color(0xFFE8734A),
        ),
        CourseStop(
          category: '카페',
          timeRange: '14:00 ~ 15:30',
          name: '와일',
          info: '카페 · 철산동 · 1km',
          icon: Icons.local_cafe,
          color: Color(0xFFC98B4A),
        ),
        CourseStop(
          category: '활동',
          timeRange: '16:00 ~ 17:00',
          name: '더홀릭 보드게임카페',
          info: '게임 · 일산동 · 1.7km',
          icon: Icons.casino,
          color: Color(0xFF4A7BC9),
        ),
      ],
      detailStopIndex: 0,
      detail: const PlaceDetail(
        category: '양식 · 철산동',
        rating: 4.6,
        reviewCount: 88,
        description: '분위기 좋은 캐주얼 양식당이에요.\n든든한 파스타와 스테이크를 즐길 수 있어요.',
        hours: '매일 11:30 ~ 21:30',
        menu: '스테이크, 크림 파스타',
        priceRange: '1인 18,000원 ~ 25,000원',
        facility: '주차, 화장실',
        icon: Icons.restaurant,
        color: Color(0xFFE8734A),
      ),
    );
