import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourist_app/services/theme_provider.dart';
import 'package:smart_tourist_app/widgets/rating_dialog.dart';
import 'package:smart_tourist_app/screens/privacy_policy_screen.dart';
import 'package:smart_tourist_app/screens/terms_conditions_screen.dart';
import 'package:smart_tourist_app/screens/cookies_policy_screen.dart';
import 'package:smart_tourist_app/screens/user_feedback_screen.dart';
import 'package:smart_tourist_app/services/logout_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_tourist_app/screens/contact_screen.dart';

class AuthoritySettingsScreen extends StatefulWidget {
  const AuthoritySettingsScreen({super.key});

  @override
  State<AuthoritySettingsScreen> createState() =>
      _AuthoritySettingsScreenState();
}

class _AuthoritySettingsScreenState extends State<AuthoritySettingsScreen> {
  // Theme Constants matching Authority Dashboard
  final Color _bgDark = const Color(0xFF0F172A); // Slate 900
  final Color _cardDark = const Color(0xFF1E293B); // Slate 800
  final Color _accentGold = const Color(0xFFF59E0B); // Amber 500
  final Color _accentSky = const Color(0xFF38BDF8); // Sky 400
  final Color _textLight = const Color(0xFFF8FAFC); // Slate 50
  final Color _textDim = const Color(0xFF94A3B8); // Slate 400

  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Note: Authority theme specifically overrides global theme for branding consistency
    // but we can still toggle dark mode logic if needed for specific internal logic.
    // For now, enforcing Command Center theme which is inherently dark.

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _accentSky),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'SYSTEM CONFIGURATION',
          style: TextStyle(
            color: _textLight,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: _cardDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('PREFERENCES'),
            Container(
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Real-time Alerts',
                    textColor: _textLight,
                    iconColor: _accentGold,
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) =>
                          setState(() => _notificationsEnabled = value),
                      activeColor: _accentGold,
                      inactiveTrackColor: Colors.black26,
                    ),
                  ),
                  _buildDivider(),
                  SettingsTile(
                    icon: Icons.brightness_6_outlined,
                    title: 'Dark Mode Override',
                    textColor: _textLight,
                    iconColor: _accentSky,
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) => themeProvider.toggleTheme(),
                      activeColor: _accentSky,
                      inactiveTrackColor: Colors.black26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('SUPPORT & LEGAL'),
            Container(
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.star_border_rounded,
                    title: 'Rate Application',
                    textColor: _textLight,
                    iconColor: _textDim,
                    onTap: () => showDialog(
                        context: context, builder: (_) => const RatingDialog()),
                  ),
                  _buildDivider(),
                  SettingsTile(
                    icon: Icons.security_rounded,
                    title: 'Privacy Protocols',
                    textColor: _textLight,
                    iconColor: _textDim,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyScreen())),
                  ),
                  _buildDivider(),
                  SettingsTile(
                    icon: Icons.gavel_rounded,
                    title: 'Terms of Service',
                    textColor: _textLight,
                    iconColor: _textDim,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TermsConditionsScreen())),
                  ),
                  _buildDivider(),
                  SettingsTile(
                    icon: Icons.data_usage_rounded,
                    title: 'Data Policy',
                    textColor: _textLight,
                    iconColor: _textDim,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CookiesPolicyScreen())),
                  ),
                  _buildDivider(),
                  SettingsTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Tech Support',
                    textColor: _textLight,
                    iconColor: _textDim,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ContactScreen())),
                  ),
                  _buildDivider(),
                  SettingsTile(
                    icon: Icons.feedback_outlined,
                    title: 'Submit Log/Feedback',
                    textColor: _textLight,
                    iconColor: _textDim,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UserFeedbackScreen())),
                  ),
                  _buildDivider(),
                  SettingsTile(
                    icon: Icons.share_rounded,
                    title: 'Share System Access',
                    textColor: _textLight,
                    iconColor: _textDim,
                    onTap: () {
                      Share.share(
                          'OFFICIAL: Secure Tourist Safety System Access Link\n\nDownload: https://play.google.com/store/apps/details?id=com.smart.tourist.security\n\nAuthorized Personnel Only.');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('SESSION'),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: SettingsTile(
                icon: Icons.power_settings_new_rounded,
                title: 'Terminate Session (Logout)',
                textColor: Colors.red.shade400,
                iconColor: Colors.red.shade400,
                onTap: () => LogoutService.showLogoutDialog(context),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'System Version 1.0.4',
                style:
                    TextStyle(color: _textDim, fontSize: 10, letterSpacing: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: const Color(0xFF94A3B8), // Slate 400
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
        height: 1,
        color: Colors.white10,
        indent: 56, // Align with text start
        endIndent: 0);
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color textColor;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.textColor,
    required this.iconColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
              if (trailing == null && onTap != null)
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white24, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
