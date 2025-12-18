import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

/// Service to handle app rating, feedback, and store navigation
class RatingService {
  // SharedPreferences keys
  static const String _keyHasRated = 'has_rated';
  static const String _keyRatingValue = 'rating_value';
  static const String _keyRatingTimestamp = 'rating_timestamp';
  static const String _keyFeedbackList = 'feedback_list';

  // TODO: Update these URLs when the app is published on stores
  // For Android: https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME
  // For iOS: https://apps.apple.com/app/idYOUR_APP_ID
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=tech.safetravel.smarttourist.smart_tourist_app';
  static const String _appStoreUrl =
      'https://apps.apple.com/app/id0000000000'; // Replace with actual App Store ID

  /// Open the appropriate app store based on platform
  Future<bool> openAppStore() async {
    try {
      String url;
      if (Platform.isAndroid) {
        url = _playStoreUrl;
      } else if (Platform.isIOS) {
        url = _appStoreUrl;
      } else {
        // For web/desktop testing, open a generic placeholder
        url = 'https://www.example.com/rate-our-app';
      }

      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
      return false;
    } catch (e) {
      print('Error opening app store: $e');
      return false;
    }
  }

  /// Save user rating to local storage
  Future<void> saveRating(int rating) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasRated, true);
      await prefs.setInt(_keyRatingValue, rating);
      await prefs.setString(
        _keyRatingTimestamp,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Error saving rating: $e');
    }
  }

  /// Check if user has already rated the app
  Future<bool> hasUserRated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyHasRated) ?? false;
    } catch (e) {
      print('Error checking rating status: $e');
      return false;
    }
  }

  /// Get the user's previous rating (if any)
  Future<int?> getUserRating() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyRatingValue);
    } catch (e) {
      print('Error getting user rating: $e');
      return null;
    }
  }

  /// Get the timestamp when user rated the app
  Future<DateTime?> getRatingTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_keyRatingTimestamp);
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (e) {
      print('Error getting rating timestamp: $e');
      return null;
    }
  }

  /// Save user feedback to local storage
  Future<void> saveFeedback(String feedback, String category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedbackList = prefs.getStringList(_keyFeedbackList) ?? [];

      // Create feedback entry with timestamp and category
      final feedbackEntry = {
        'feedback': feedback,
        'category': category,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Store as JSON string
      feedbackList.add(feedbackEntry.toString());
      await prefs.setStringList(_keyFeedbackList, feedbackList);
    } catch (e) {
      print('Error saving feedback: $e');
    }
  }

  /// Get all feedback submissions
  Future<List<String>> getAllFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_keyFeedbackList) ?? [];
    } catch (e) {
      print('Error getting feedback: $e');
      return [];
    }
  }

  /// Clear all rating data (useful for testing)
  Future<void> clearRatingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyHasRated);
      await prefs.remove(_keyRatingValue);
      await prefs.remove(_keyRatingTimestamp);
    } catch (e) {
      print('Error clearing rating data: $e');
    }
  }

  /// Get rating analytics (for developer insights)
  Future<Map<String, dynamic>> getRatingAnalytics() async {
    try {
      final hasRated = await hasUserRated();
      final rating = await getUserRating();
      final timestamp = await getRatingTimestamp();
      final feedbackCount = (await getAllFeedback()).length;

      return {
        'has_rated': hasRated,
        'rating': rating,
        'timestamp': timestamp?.toIso8601String(),
        'feedback_count': feedbackCount,
      };
    } catch (e) {
      print('Error getting analytics: $e');
      return {};
    }
  }
}
