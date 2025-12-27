import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourist_app/services/theme_provider.dart';

class CookiesPolicyScreen extends StatelessWidget {
  const CookiesPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Force Dark Professional Theme for consistency
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final bgColor =
        isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor =
        isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final accentColor = isDarkMode
        ? const Color(0xFF38BDF8)
        : const Color(0xFF0284C7); // Sky Blue

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('DATA POLICY & COOKIES',
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 16)),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
              color: isDarkMode ? Colors.white10 : Colors.black12, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.data_usage, color: accentColor, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DATA RETENTION PROTOCOLS',
                            style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text(
                            'Standard Operating Procedures for local data storage and tracking packets (Cookies).',
                            style: TextStyle(
                                color: textColor.withOpacity(0.6),
                                fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('1. PROTOCOL OVERVIEW', accentColor),
            _buildText(
                'This document outlines the usage of tracking technologies (cookies) to maintain system integrity and user session persistence.',
                textColor),

            const SizedBox(height: 24),
            _buildSectionTitle('2. COOKIE DEFINITIONS', accentColor),
            _buildText(
                'Cookies are small data packets stored on the client terminal. These are essential for maintaining secure sessions and improving command response times.',
                textColor),

            const SizedBox(height: 24),
            _buildSectionTitle('3. USAGE CLASSIFICATION', accentColor),
            _buildCookieGrid(cardColor, textColor, accentColor),

            const SizedBox(height: 24),
            _buildSectionTitle('4. THIRD-PARTY INTEGRATIONS', accentColor),
            _buildText(
                'External modules (Google Analytics, Firebase, Ads) may deploy independent tracking markers. Review their respective protocols for details.',
                textColor),

            const SizedBox(height: 24),
            _buildSectionTitle('5. OPERATOR CONTROL', accentColor),
            _buildText(
                'Operators may manually purge data packets via terminal settings. CAUTION: Purging may result in session termination or loss of personalized configurations.',
                textColor),

            const SizedBox(height: 32),
            Divider(color: textColor.withOpacity(0.2)),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text('SYSTEM DEVELOPERS',
                      style: TextStyle(
                          color: textColor.withOpacity(0.5),
                          fontSize: 10,
                          letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text('Akshay Rathod & Meghana Mehetre',
                      style: TextStyle(
                          color: textColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('LAST UPDATE: 30/11/2025',
                      style: TextStyle(
                          color: textColor.withOpacity(0.4),
                          fontSize: 10,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5)),
    );
  }

  Widget _buildText(String text, Color color) {
    return Text(text,
        style: TextStyle(
            color: color.withOpacity(0.8), height: 1.6, fontSize: 14));
  }

  Widget _buildCookieGrid(Color cardColor, Color textColor, Color accentColor) {
    final items = [
      {'title': 'ESSENTIAL', 'desc': 'Critical for system operations.'},
      {'title': 'PERFORMANCE', 'desc': 'Monitors system latency & errors.'},
      {'title': 'PREFERENCE', 'desc': 'Stores user configurations.'},
      {'title': 'SECURITY', 'desc': 'Validates user authentication tokens.'},
    ];

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item['title']!,
                  style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              const SizedBox(height: 4),
              Text(item['desc']!,
                  style: TextStyle(
                      color: textColor.withOpacity(0.7), fontSize: 10)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
