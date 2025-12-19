import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourist_app/services/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CookiesPolicyScreen extends StatelessWidget {
  const CookiesPolicyScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Cookies Policy',
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(isDarkMode),
              const SizedBox(height: 24),

              // Introduction
              _buildSection(
                isDarkMode,
                '1. Introduction',
                'This Cookies Policy explains how our application uses cookies or similar tracking technologies to enhance user experience. By using our application, you agree to the use of cookies as described below.',
              ),

              // What Are Cookies
              _buildSection(
                isDarkMode,
                '2. What Are Cookies?',
                'Cookies are small files or data packets stored on your device. They help apps remember user preferences, save login sessions, and analyze usage patterns to provide a better experience.',
              ),

              // How We Use Cookies
              _buildSection(
                isDarkMode,
                '3. How We Use Cookies',
                'We may use cookies for:',
              ),
              _buildBulletList(isDarkMode, [
                'Saving user preferences and settings',
                'Keeping users logged in',
                'Enhancing UI personalization (themes, mode, layout)',
                'Analyzing user behavior and improving performance',
                'Reducing load time and caching essential data',
              ]),

              // Types of Cookies
              _buildSection(
                isDarkMode,
                '4. Types of Cookies We May Use',
                '',
              ),
              _buildCookieTable(isDarkMode),
              _buildNote(isDarkMode,
                  'We do not use cookies to collect sensitive personal information without consent.'),

              // Third-Party Cookies
              _buildSection(
                isDarkMode,
                '5. Third-Party Cookies',
                'Some third-party services integrated into the app (ex: Google Analytics, Firebase, Ads) may store their own tracking cookies. Users should review independent policies of respective service providers.',
              ),

              // User Control
              _buildSection(
                isDarkMode,
                '6. User Control Over Cookies',
                'You have full control to enable, disable, or clear cookies from your device settings anytime. However, disabling cookies may affect certain app features or cause limited functionality.',
              ),

              // Data Security
              _buildSection(
                isDarkMode,
                '7. Data Security',
                'We implement reasonable security measures to safeguard cookie data. While we strive to protect information, no system is fully secure.',
              ),

              // Updates to Policy
              _buildSection(
                isDarkMode,
                '8. Updates to This Policy',
                'We may modify or update this Cookies Policy occasionally. Users will be notified of major changes within the app.',
              ),

              // Contact Information
              _buildSection(
                isDarkMode,
                '9. Contact Information',
                'If you have questions about our cookie usage, contact:',
              ),
              const SizedBox(height: 12),
              _buildContactInfo(isDarkMode),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1D2640) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4B3F9E).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cookie_outlined,
                  color: Color(0xFF4B3F9E),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Safety Tourist',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Developers: Akshay Rathod & Meghana Mehetre',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: isDarkMode ? Colors.white10 : Colors.grey[300]),
          const SizedBox(height: 8),
          Text(
            'Last Updated: 30/11/2025',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white60 : Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(bool isDarkMode, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletList(bool isDarkMode, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDarkMode ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 15,
                            color:
                                isDarkMode ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCookieTable(bool isDarkMode) {
    final cookies = [
      {
        'type': 'Essential Cookies',
        'purpose': 'Required for core app operations'
      },
      {
        'type': 'Performance Cookies',
        'purpose': 'Monitor usage & improve functionality'
      },
      {
        'type': 'Preference Cookies',
        'purpose': 'Store language, theme, notification settings'
      },
      {
        'type': 'Analytics Cookies',
        'purpose': 'Track behavior for app optimization'
      },
      {
        'type': 'Session Cookies',
        'purpose': 'Temporary storage while app is running'
      },
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1D2640) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white10 : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: cookies.asMap().entries.map((entry) {
          final index = entry.key;
          final cookie = entry.value;
          return Container(
            decoration: BoxDecoration(
              border: index < cookies.length - 1
                  ? Border(
                      bottom: BorderSide(
                        color: isDarkMode ? Colors.white10 : Colors.grey[300]!,
                      ),
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      cookie['type']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Text(
                      cookie['purpose']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNote(bool isDarkMode, String note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4B3F9E).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF4B3F9E).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: Color(0xFF4B3F9E),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              note,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1D2640) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildContactItem(
            isDarkMode,
            Icons.email_outlined,
            'Email',
            'rathod4520@gmail.com',
            'mailto:rathod4520@gmail.com',
          ),
          const SizedBox(height: 12),
          Divider(color: isDarkMode ? Colors.white10 : Colors.grey[300]),
          const SizedBox(height: 12),
          _buildContactItem(
            isDarkMode,
            Icons.link,
            'LinkedIn',
            'Akshay Rathod',
            'https://www.linkedin.com/in/akshay-rathod-aaab52206/',
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    bool isDarkMode,
    IconData icon,
    String label,
    String value,
    String url,
  ) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4B3F9E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF4B3F9E),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode ? Colors.white38 : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
