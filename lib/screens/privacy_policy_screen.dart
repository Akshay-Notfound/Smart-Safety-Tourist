import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourist_app/services/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
                'This Privacy Policy explains how we collect, use, store, and protect your information when you use our mobile application. By using our application, you agree to the practices described in this policy.',
              ),

              // Information We Collect
              _buildSection(
                isDarkMode,
                '2. Information We Collect',
                'We may collect the following types of data:',
              ),
              _buildSubSection(
                  isDarkMode, 'a) Personal Information (If provided by user)', [
                'Name',
                'Email address',
                'Contact details',
              ]),
              _buildSubSection(isDarkMode, 'b) Non-Personal / Automatic Data', [
                'Device information (model, system version)',
                'App usage statistics',
                'Crash logs and performance analytics',
              ]),
              _buildNote(isDarkMode,
                  'We only collect information necessary to improve your experience.'),

              // How We Use Your Information
              _buildSection(
                isDarkMode,
                '3. How We Use Your Information',
                'We may use the collected data for:',
              ),
              _buildBulletList(isDarkMode, [
                'Improving app performance and user experience',
                'Bug fixing & feature enhancement',
                'Sending notifications or updates',
                'Personalization of app features',
                'Analytics and usage insights',
              ]),

              // Permissions
              _buildSection(
                isDarkMode,
                '4. Permissions We Use & Why',
                '',
              ),
              _buildPermissionTable(isDarkMode),
              _buildNote(isDarkMode,
                  'We never access any permission without user consent.'),

              // Third-Party Services
              _buildSection(
                isDarkMode,
                '5. Third-Party Services',
                'We may use third-party tools such as Firebase, Google Analytics, or Advertisement services. These providers may collect usage data as per their policies. Users should refer to their respective privacy policies for more details.',
              ),

              // Data Security
              _buildSection(
                isDarkMode,
                '6. Data Security',
                'We follow industry-standard practices to protect user data. However, no method of digital transfer or storage is 100% secure, and we cannot guarantee absolute security.',
              ),

              // Data Sharing Policy
              _buildSection(
                isDarkMode,
                '7. Data Sharing Policy',
                'We do not sell or trade user information to any third parties. Data may only be shared for:',
              ),
              _buildBulletList(isDarkMode, [
                'Legal compliance',
                'User-requested services',
                'App functionality through trusted providers',
              ]),

              // Children's Privacy
              _buildSection(
                isDarkMode,
                '8. Children\'s Privacy',
                'Our app does not knowingly collect data from children under the age of 13. If such information is accidentally collected, users may request removal.',
              ),

              // User Rights
              _buildSection(
                isDarkMode,
                '9. User Rights',
                'You have the right to:',
              ),
              _buildBulletList(isDarkMode, [
                'Access your personal data',
                'Request deletion/modification',
                'Withdraw permission access anytime',
              ]),
              _buildNote(isDarkMode, 'You can contact us for any request.'),

              // Contact Us
              _buildSection(
                isDarkMode,
                '10. Contact Us',
                'If you have questions regarding this Privacy Policy, you may contact:',
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
                  Icons.shield_outlined,
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

  Widget _buildSubSection(bool isDarkMode, String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDarkMode ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDarkMode ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
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

  Widget _buildPermissionTable(bool isDarkMode) {
    final permissions = [
      {
        'permission': 'Camera',
        'purpose': 'For scanning QR/recognition features'
      },
      {
        'permission': 'Storage',
        'purpose': 'To save images, documents, or user data'
      },
      {
        'permission': 'Internet',
        'purpose': 'For online features and cloud sync'
      },
      {
        'permission': 'Notification Access',
        'purpose': 'To send alerts and updates'
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
        children: permissions.asMap().entries.map((entry) {
          final index = entry.key;
          final perm = entry.value;
          return Container(
            decoration: BoxDecoration(
              border: index < permissions.length - 1
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
                      perm['permission']!,
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
                      perm['purpose']!,
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
          Icon(
            Icons.info_outline,
            size: 20,
            color: const Color(0xFF4B3F9E),
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
