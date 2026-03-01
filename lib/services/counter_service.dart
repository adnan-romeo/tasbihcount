import 'package:cloud_firestore/cloud_firestore.dart';

class CounterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> loadUserCounts(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore.collection('users').doc(uid).get();

    if (!snapshot.exists) {
      return {'today': 0, 'week': 0, 'month': 0};
    }

    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};
    final Map<String, dynamic> counts =
        (data['counts'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return {
      'today': (counts['today'] as num?)?.toInt() ?? 0,
      'week': (counts['week'] as num?)?.toInt() ?? 0,
      'month': (counts['month'] as num?)?.toInt() ?? 0,
    };
  }

  Future<void> saveUserCounts(
    String uid, {
    required int today,
    required int week,
    required int month,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'counts': {
        'today': today,
        'week': week,
        'month': month,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
