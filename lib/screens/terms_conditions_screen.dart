import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourist_app/services/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
          'Terms & Conditions',
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

              // Acceptance of Terms
              _buildSection(
                isDarkMode,
                '1. Acceptance of Terms',
                'By downloading, installing, or using this application, you agree to comply with these Terms & Conditions. If you do not agree, please discontinue use immediately.',
              ),

              // Use of Application
              _buildSection(
                isDarkMode,
                '2. Use of Application',
                'You agree to use the app responsibly and for lawful purposes only. You must not:',
              ),
              _buildBulletList(isDarkMode, [
                'Attempt to hack, modify or damage the app',
                'Misuse the services for unauthorised activities',
                'Upload harmful or malicious content',
              ]),

              // User Accounts
              _buildSection(
                isDarkMode,
                '3. User Accounts',
                'If your app contains login or account creation:',
              ),
              _buildBulletList(isDarkMode, [
                'You are responsible for maintaining account security',
                'Do not share your account credentials',
                'We reserve the right to suspend accounts involved in misuse',
              ]),

              // Intellectual Property
              _buildSection(
                isDarkMode,
                '4. Intellectual Property',
                'All content, UI/UX design, logos, code and graphics are owned by the developer. Copying, redistributing, or reselling the app or any of its features is prohibited.',
              ),

              // In-App Purchases
              _buildSection(
                isDarkMode,
                '5. In-App Purchases / Payments',
                'If your app includes paid features:',
              ),
              _buildBulletList(isDarkMode, [
                'Payments are processed through secured third-party gateways',
                'Purchases are final unless legally required for refund',
                'Unauthorized transactions must be reported immediately',
              ]),

              // Third-Party Services
              _buildSection(
                isDarkMode,
                '6. Third-Party Services',
                'The app may use third-party frameworks like Firebase, Analytics, or Ads. We are not responsible for their actions or policies — users should review them individually.',
              ),

              // Limitation of Liability
              _buildSection(
                isDarkMode,
                '7. Limitation of Liability',
                'We are not responsible for:',
              ),
              _buildBulletList(isDarkMode, [
                'Data loss',
                'Device damage',
                'Service interruptions',
                'Misuse of the app by the user',
              ]),
              _buildNote(isDarkMode, 'Use of the app is at your own risk.'),

              // App Updates & Modifications
              _buildSection(
                isDarkMode,
                '8. App Updates & Modifications',
                'We may introduce new features, remove functionalities, or update terms anytime without prior notice. Continued use means you accept future changes.',
              ),

              // Account/Data Termination
              _buildSection(
                isDarkMode,
                '9. Account/Data Termination',
                'We reserve full rights to suspend or terminate user accounts or restrict access if:',
              ),
              _buildBulletList(isDarkMode, [
                'Terms are violated',
                'Illegal or harmful activity is detected',
              ]),

              // Governing Law
              _buildSection(
                isDarkMode,
                '10. Governing Law',
                'These terms are governed by applicable local and international digital service laws.',
              ),

              // Contact Information
              _buildSection(
                isDarkMode,
                '11. Contact Information',
                'For queries or clarifications related to Terms & Conditions:',
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
                  Icons.article_outlined,
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
