import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourist_app/services/theme_provider.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Professional Palette (Matching Privacy Policy)
    final bgColor =
        isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor =
        isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);

    final activeColor = isDarkMode
        ? const Color(0xFFF59E0B)
        : const Color(0xFFD97706); // Amber for Terms
    final dividerColor = isDarkMode ? Colors.white12 : Colors.black12;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'TERMS OF SERVICE',
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: dividerColor, height: 1.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(cardColor, textColor, activeColor, isDarkMode),
              const SizedBox(height: 32),
              _buildSectionTitle('1. ACCEPTANCE', activeColor),
              _buildSectionBody(
                  'By accessing or using the Smart Safety Tourist platform, you agree to be bound by these restrictions. Unauthorized access is a punishable offense.',
                  textColor),
              const SizedBox(height: 24),
              _buildSectionTitle('2. USER CONDUCT', activeColor),
              _buildSectionBody(
                  'All users must adhere to strict guidelines:', textColor),
              _buildBulletList([
                'Do not compromise system integrity or security protocols.',
                'False reporting of emergencies is strictly prohibited.',
                'Authority credentials must remain confidential.'
              ], textColor, isDarkMode),
              const SizedBox(height: 24),
              _buildSectionTitle('3. LIABILITY', activeColor),
              _buildSectionBody(
                  'The platform is provided "as is". Developers are not liable for direct, indirect, incidental, or consequential damages resulting from the use or inability to use the service.',
                  textColor),
              const SizedBox(height: 24),
              _buildSectionTitle('4. TERMINATION', activeColor),
              _buildSectionBody(
                  'We reserve the right to suspend or terminate accounts found violating these terms or local laws without prior notice.',
                  textColor),
              const SizedBox(height: 48),
              Center(
                child: Text(
                  'Smart Safety Tourist Initiative',
                  style: TextStyle(
                    color: textColor.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Legal Compliance Verified',
                  style: TextStyle(
                    color: textColor.withOpacity(0.3),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      Color cardColor, Color textColor, Color accentColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.gavel_rounded, color: accentColor, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usage Agreement',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Read Carefully',
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSectionBody(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          color: color.withOpacity(0.8),
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildBulletList(List<String> items, Color color, bool isDark) {
    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: CircleAvatar(
                          radius: 2, backgroundColor: color.withOpacity(0.5)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: color.withOpacity(0.8),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
