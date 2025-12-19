import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submit feedback to Firebase Firestore
  /// Returns null if successful, or error message if failed
  Future<String?> submitFeedback({
    required String feedbackType,
    required String message,
    String? name,
    String? email,
    double? rating,
  }) async {
    try {
      // Get current user if authenticated
      final user = _auth.currentUser;

      // Prepare feedback data
      final feedbackData = {
        'feedbackType': feedbackType,
        'message': message,
        'name': name ?? 'Anonymous',
        'email': email ?? '',
        'rating': rating,
        'userId': user?.uid ?? 'anonymous',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, reviewed, resolved
        'platform': 'mobile',
      };

      // Submit to Firestore
      await _firestore.collection('feedbacks').add(feedbackData);

      return null; // Success
    } catch (e) {
      print('Error submitting feedback: $e');
      return e.toString(); // Return actual error
    }
  }

  /// Get user's previous feedback submissions
  Future<List<Map<String, dynamic>>> getUserFeedback() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('feedbacks')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching user feedback: $e');
      return [];
    }
  }

  /// Get feedback count by type for analytics
  Future<Map<String, int>> getFeedbackAnalytics() async {
    try {
      final snapshot = await _firestore.collection('feedbacks').get();

      final analytics = <String, int>{
        'Bug Report': 0,
        'Feature Request': 0,
        'Improvement': 0,
        'Positive': 0,
        'Other': 0,
      };

      for (var doc in snapshot.docs) {
        final type = doc.data()['feedbackType'] as String?;
        if (type != null && analytics.containsKey(type)) {
          analytics[type] = (analytics[type] ?? 0) + 1;
        }
      }

      return analytics;
    } catch (e) {
      print('Error fetching analytics: $e');
      return {};
    }
  }
}
