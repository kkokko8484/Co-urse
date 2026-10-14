import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';
import 'course_api_service.dart';

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
}
