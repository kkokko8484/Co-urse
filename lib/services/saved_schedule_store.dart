import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// 사용자가 "이 코스로 확정하기" 후 일정에 저장한 코스 한 건
class SavedSchedule {
  final String id;
  final RecommendedCourse course;
  final DateTime date;
  final String startTime; // 예: '12:00'
  final String endTime; // 예: '17:00'

  const SavedSchedule({
    required this.id,
    required this.course,
    required this.date,
    required this.startTime,
    required this.endTime,
  });
}

/// 저장된 코스 일정을 앱 전체에서 공유하는 저장소.
/// (현재는 메모리에만 보관하므로 앱을 완전히 종료하면 사라진다.)
class SavedScheduleStore extends ChangeNotifier {
  SavedScheduleStore._();

  static final SavedScheduleStore instance = SavedScheduleStore._();

  final List<SavedSchedule> _items = [];

  /// 날짜, 시작 시간 순으로 정렬된 일정 목록
  List<SavedSchedule> get items {
    final sorted = [..._items]
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return a.startTime.compareTo(b.startTime);
      });
    return List.unmodifiable(sorted);
  }

  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;

  void add({
    required RecommendedCourse course,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) {
    _items.add(
      SavedSchedule(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        course: course,
        date: date,
        startTime: startTime,
        endTime: endTime,
      ),
    );
    notifyListeners();
  }

  void remove(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}