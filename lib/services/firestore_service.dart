import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';
import 'course_api_service.dart';

/// Firebase에 코스/일정을 저장하고, 저장한 일정을 화면에 제공하는 서비스.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('로그인이 필요한 기능입니다.');
    }

    return user.uid;
  }

  Future<String> saveCourse({
    required CourseFlowData data,
    required RecommendedCourse course,
  }) async {
    final userId = _currentUserId;
    final location = CourseApiServiceLocation.selectedLocation;

    final courseRef = await _firestore.collection('courses').add({
      'userId': userId,
      'mode': data.mode.name,
      'withWhom': data.withWhom,
      'situation': data.situation,
      'foodTypes': data.foodTypes,
      'moods': data.moods,
      'priorities': data.priorities,
      'budget': data.budget,
      'avoidFactors': data.avoidFactors,
      'meetingLocation': location == null
          ? null
          : {
        'displayName': location.displayName,
        'address': location.address,
        'x': location.x,
        'y': location.y,
      },
      'headerTitle': course.headerTitle,
      'estimatedDuration': course.estimatedDuration,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final batch = _firestore.batch();

    for (final stop in course.stops) {
      final placeRef = _firestore.collection('course_places').doc();

      batch.set(placeRef, {
        'userId': userId,
        'courseId': courseRef.id,
        'category': stop.category,
        'timeRange': stop.timeRange,
        'name': stop.name,
        'info': stop.info,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    return courseRef.id;
  }

  Future<void> saveSchedule({
    required String courseId,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    final userId = _currentUserId;

    await _firestore.collection('schedules').add({
      'userId': userId,
      'courseId': courseId,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 현재 로그인한 사용자의 일정을 실시간으로 조회합니다.
  /// 일정 문서의 courseId를 이용해 courses와 course_places 정보도 함께 읽습니다.
  Stream<List<SavedScheduleRecord>> watchSchedules() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<List<SavedScheduleRecord>>.error(
          Exception('로그인이 필요한 기능입니다. 로그인한 뒤 다시 시도해주세요.'),
        );
      }

      return _firestore
          .collection('schedules')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .asyncMap((snapshot) async {
        final records = await Future.wait(
          snapshot.docs.map((doc) => _loadScheduleRecord(doc)),
        );
        records.sort((a, b) => b.date.compareTo(a.date));
        return records;
      });
    });
  }

  Future<SavedScheduleRecord> _loadScheduleRecord(
      QueryDocumentSnapshot<Map<String, dynamic>> scheduleDoc,
      ) async {
    final scheduleData = scheduleDoc.data();
    final courseId = (scheduleData['courseId'] ?? '').toString();

    Map<String, dynamic> courseData = <String, dynamic>{};
    if (courseId.isNotEmpty) {
      final courseSnapshot =
      await _firestore.collection('courses').doc(courseId).get();
      courseData = courseSnapshot.data() ?? <String, dynamic>{};
    }

    final placeSnapshot = courseId.isEmpty
        ? null
        : await _firestore
        .collection('course_places')
        .where('courseId', isEqualTo: courseId)
        .get();

    final stops = (placeSnapshot?.docs ?? [])
        .map((doc) => SavedCoursePlace.fromMap(doc.id, doc.data()))
        .toList()
      ..sort((a, b) => a.timeRange.compareTo(b.timeRange));

    final rawParticipants = courseData['withWhom'];
    final participants = rawParticipants is Iterable
        ? rawParticipants.map((value) => value.toString()).where((value) => value.trim().isNotEmpty).toList()
        : <String>[];
    if (!participants.contains('나')) participants.add('나');
    if (participants.isEmpty) participants.add('나');

    return SavedScheduleRecord(
      id: scheduleDoc.id,
      courseId: courseId,
      title: (courseData['headerTitle'] ?? '저장된 코스').toString(),
      estimatedDuration: (courseData['estimatedDuration'] ?? '').toString(),
      date: _toDateTime(scheduleData['date']),
      startTime: (scheduleData['startTime'] ?? '12:00').toString(),
      endTime: (scheduleData['endTime'] ?? '13:00').toString(),
      participants: participants,
      stops: stops,
    );
  }

  DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// 일정 날짜/시간을 수정합니다.
  Future<void> updateSchedule({
    required String scheduleId,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    final userId = _currentUserId;
    final ref = _firestore.collection('schedules').doc(scheduleId);
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.data()?['userId'] != userId) {
      throw Exception('수정할 일정을 찾을 수 없습니다.');
    }

    await ref.update({
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'startTime': startTime,
      'endTime': endTime,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 일정 문서만 삭제합니다. 코스 정보는 다른 곳에서 재사용될 가능성이 있어 보존합니다.
  Future<void> deleteSchedule(String scheduleId) async {
    final userId = _currentUserId;
    final ref = _firestore.collection('schedules').doc(scheduleId);
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.data()?['userId'] != userId) {
      throw Exception('삭제할 일정을 찾을 수 없습니다.');
    }
    await ref.delete();
  }
}

/// 일정 목록/상세 UI에 필요한 형태로 합친 데이터입니다.
class SavedScheduleRecord {
  final String id;
  final String courseId;
  final String title;
  final String estimatedDuration;
  final DateTime date;
  final String startTime;
  final String endTime;
  final List<String> participants;
  final List<SavedCoursePlace> stops;

  const SavedScheduleRecord({
    required this.id,
    required this.courseId,
    required this.title,
    required this.estimatedDuration,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.participants,
    required this.stops,
  });

  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduleDay = DateTime(date.year, date.month, date.day);
    return scheduleDay.isBefore(today);
  }
}

class SavedCoursePlace {
  final String id;
  final String name;
  final String category;
  final String timeRange;
  final String info;

  const SavedCoursePlace({
    required this.id,
    required this.name,
    required this.category,
    required this.timeRange,
    required this.info,
  });

  factory SavedCoursePlace.fromMap(String id, Map<String, dynamic> map) {
    return SavedCoursePlace(
      id: id,
      name: (map['name'] ?? '이름 없는 장소').toString(),
      category: (map['category'] ?? '장소').toString(),
      timeRange: (map['timeRange'] ?? '').toString(),
      info: (map['info'] ?? '').toString(),
    );
  }

  List<String> get _infoParts => info
      .split(RegExp(r'[·•]'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  String get location {
    final parts = _infoParts;
    if (parts.isEmpty) return '';
    final distanceIndex = parts.indexWhere(_looksLikeDistance);
    final nonDistance = [
      for (var i = 0; i < parts.length; i++)
        if (i != distanceIndex) parts[i],
    ];
    if (nonDistance.length >= 2) return nonDistance[1];
    return nonDistance.isNotEmpty ? nonDistance.first : parts.first;
  }

  String get distance {
    for (final part in _infoParts.reversed) {
      if (_looksLikeDistance(part)) return part;
    }
    return '';
  }

  bool _looksLikeDistance(String value) =>
      RegExp(r'^\d+(?:\.\d+)?\s*(?:km|m)$', caseSensitive: false)
          .hasMatch(value.trim());
}
