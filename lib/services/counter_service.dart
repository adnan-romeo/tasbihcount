import 'package:cloud_firestore/cloud_firestore.dart';

class CounterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> loadUserCounts(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore.collection('users').doc(uid).get();

    if (!snapshot.exists) {
      return {'today': 0, 'week': 0, 'month': 0, 'lifetime': 0};
    }

    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};
    final Map<String, dynamic> counts =
        (data['counts'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    int today = (counts['today'] as num?)?.toInt() ?? 0;
    int week = (counts['week'] as num?)?.toInt() ?? 0;
    int month = (counts['month'] as num?)?.toInt() ?? 0;
    int lifetime = (counts['lifetime'] as num?)?.toInt() ?? 0;

    final Timestamp? updatedAtTimestamp = data['updatedAt'] as Timestamp?;
    final DateTime? lastUpdated = updatedAtTimestamp?.toDate();

    if (lastUpdated != null) {
      final now = DateTime.now();

      // 1. Daily Reset (12 AM)
      if (!_isSameDay(now, lastUpdated)) {
        today = 0;
      }

      // 2. Weekly Reset (Friday)
      final DateTime lastFriday = _getLastFriday(now);
      if (lastUpdated.isBefore(lastFriday)) {
        week = 0;
      }

      // 3. Monthly Reset (1st of month)
      if (!_isSameMonth(now, lastUpdated)) {
        month = 0;
      }
    }

    return {
      'today': today,
      'week': week,
      'month': month,
      'lifetime': lifetime,
    };
  }

  Future<void> saveUserCounts(
    String uid, {
    required int today,
    required int week,
    required int month,
    required int lifetime,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'counts': {
        'today': today,
        'week': week,
        'month': month,
        'lifetime': lifetime,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  DateTime _getLastFriday(DateTime date) {
    // weekday: Mon=1, ... Fri=5, ... Sun=7
    final int daysToSubtract = (date.weekday - DateTime.friday + 7) % 7;
    final DateTime lastFri = date.subtract(Duration(days: daysToSubtract));
    return DateTime(lastFri.year, lastFri.month, lastFri.day); // Strip time
  }
}
