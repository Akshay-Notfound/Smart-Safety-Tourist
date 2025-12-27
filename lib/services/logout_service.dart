import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_tourist_app/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourist_app/services/theme_provider.dart';

class LogoutService {
  /// Show logout confirmation dialog
  static Future<void> showLogoutDialog(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    // Professional/Command Center Theme Colors
    final bgColor =
        isDarkMode ? const Color(0xFF1E293B) : Colors.white; // Slate 800
    final textColor =
        isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final accentColor = const Color(0xFFF59E0B); // Amber for Warning
    final dangerColor = const Color(0xFFEF4444); // Red for Logout

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4), // Sharp corners
            side: isDarkMode
                ? BorderSide(color: Colors.white12)
                : BorderSide.none,
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: accentColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'TERMINATE SESSION?',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Secure connection will be closed. You will need to re-authenticate to access the system.',
            style: TextStyle(
              color: textColor.withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 0,
              ),
              child: const Text(
                'TERMINATE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Perform logout operation
  static Future<void> performLogout(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFF59E0B)), // Amber
        ),
      );

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Clear local storage (keep theme preference)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('last_login');

      // Close loading indicator
      if (context.mounted) Navigator.of(context).pop();

      // Navigate to login screen and clear navigation stack
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading indicator if still showing
      if (context.mounted) Navigator.of(context).pop();

      // Show error dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: Colors.red, width: 1),
            ),
            title: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 12),
                Text('SYSTEM ERROR',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
              ],
            ),
            content: Text(
              'Logout sequence failed: ${e.toString()}',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ACKNOWLEDGE',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      }
    }
  }
}
