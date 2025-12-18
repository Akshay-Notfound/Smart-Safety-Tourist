import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourist_app/services/theme_provider.dart';
import 'package:smart_tourist_app/widgets/rating_dialog.dart';
import 'package:smart_tourist_app/screens/privacy_policy_screen.dart';
import 'package:smart_tourist_app/screens/terms_conditions_screen.dart';
import 'package:smart_tourist_app/screens/cookies_policy_screen.dart';
import 'package:smart_tourist_app/screens/user_feedback_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_tourist_app/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  Future<void> _showLogoutDialog() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1D2640) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4B3F9E).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_outlined,
                  color: Color(0xFF4B3F9E),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to log out?\nYou will need to sign in again to access your account.',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey[700],
              fontSize: 15,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B3F9E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: Color(0xFF4B3F9E)),
        ),
      );

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Clear local storage (optional - keep theme preference)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('last_login');

      // Close loading indicator
      if (mounted) Navigator.of(context).pop();

      // Navigate to login screen and clear navigation stack
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading indicator if still showing
      if (mounted) Navigator.of(context).pop();

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 12),
                Text('Logout Failed'),
              ],
            ),
            content:
                Text('An error occurred while logging out: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0A0E21) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDarkMode ? Colors.white70 : Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'App Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your app preferences',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1D2640) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notification',
                      textColor: isDarkMode ? Colors.white : Colors.black87,
                      tileColor: isDarkMode
                          ? const Color(0xFF2A3256)
                          : Colors.grey[50]!,
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) =>
                            setState(() => _notificationsEnabled = value),
                        activeColor: const Color(0xFF4B3F9E),
                      ),
                    ),
                    _buildDivider(isDarkMode),
                    SettingsTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      textColor: isDarkMode ? Colors.white : Colors.black87,
                      tileColor: isDarkMode
                          ? const Color(0xFF2A3256)
                          : Colors.grey[50]!,
                      trailing: Switch(
                        value: isDarkMode,
                        onChanged: (value) => themeProvider.toggleTheme(),
                        activeColor: const Color(0xFF4B3F9E),
                      ),
                    ),
                    _buildDivider(isDarkMode),
                    SettingsTile(
                      icon: Icons.star_outline,
                      title: 'Rate App',
                      textColor: isDarkMode ? Colors.white : Colors.black87,
                      tileColor: isDarkMode
                          ? const Color(0xFF2A3256)
                          : Colors.grey[50]!,
                      onTap: () => showDialog(
                          context: context,
                          builder: (_) => const RatingDialog()),
                    ),
                    _buildDivider(isDarkMode),
                    SettingsTile(
                      icon: Icons.share_outlined,
                      title: 'Share App',
                      textColor: isDarkMode ? Colors.white : Colors.black87,
                      tileColor: isDarkMode
                          ? const Color(0xFF2A3256)
                          : Colors.grey[50]!,
                    ),
                    _buildDivider(isDarkMode),
                    SettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Privacy Policy',
                      textColor: isDarkMode ? Colors.white : Colors.black87,
                      tileColor: isDarkMode
                          ? const Color(0xFF2A3256)
                          : Colors.grey[50]!,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen())),
                    ),
                    _buildDivider(isDarkMode),
                    SettingsTile(
                      icon: Icons.description_outlined,
                      title: 'Terms and Conditions',
                      textColor: isDarkMode ? Colors.white : Colors.black87,
                      tileColor: isDarkMode
                          ? const Color(0xFF2A3256)
                          : Colors.grey[50]!,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TermsConditionsScreen())),
                    ),
                    _buildDivider(isDarkMode),
                    SettingsTile(
                      icon: Icons.cookie_outlined,
                      title: 'Cookies Policy',
                      textColor: isDarkMode ? Colors.white : Colors.black87,
                      tileColor: isDarkMode
                          ? const Color(0xFF2A3256)
                          : Colors.grey[50]!,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CookiesPolicyScreen())),
                    ),
                    _buildDivider(isDarkMode),
                    SettingsTile(
                      icon: Icons.contact_support_outlined,
                      title: 'Contact',
                      textColor: isDarkMode ? Colors.white : Colors.black87,
                      tileColor: isDarkMode
                          ? const Color(0xFF2A3256)
                          : Colors.grey[50]!,
                    ),
                    _buildDivider(isDarkMode),
                    SettingsTile(
                      icon: Icons.feedback_outlined,
                      title: 'Feedback',
                      textColor: isDarkMode ? Colors.white : Colors.black87,
                      tileColor: isDarkMode
                          ? const Color(0xFF2A3256)
                          : Colors.grey[50]!,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UserFeedbackScreen())),
                    ),
                    _buildDivider(isDarkMode),
                    SettingsTile(
                      icon: Icons.logout_outlined,
                      title: 'Logout',
                      textColor: isDarkMode ? Colors.white : Colors.black87,
                      tileColor: isDarkMode
                          ? const Color(0xFF2A3256)
                          : Colors.grey[50]!,
                      onTap: _showLogoutDialog,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
        height: 1,
        color: isDarkMode ? Colors.white10 : Colors.grey[300]!,
        indent: 60,
        endIndent: 20);
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color textColor;
  final Color tileColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.textColor,
    required this.tileColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: tileColor,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF4B3F9E)),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }
}
