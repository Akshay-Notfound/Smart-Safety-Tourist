import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourist_app/services/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  final String _supportEmail = 'rathod4529@gmail.com';
  final String _supportPhone = '+918454842474';
  final String _websiteUrl = 'https://yourwebsite.com';
  final String _whatsappUrl = 'https://wa.me/message/GSUE3AWAGR4AD1';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('UPLINK FAILED: $urlString')));
      }
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: _encodeQueryParameters(
          <String, String>{'subject': 'Support Request - Smart Tourist App'}),
    );
    await _launchUrl(emailLaunchUri.toString());
  }

  Future<void> _launchPhone() async {
    final Uri phoneLaunchUri = Uri(scheme: 'tel', path: _supportPhone);
    await _launchUrl(phoneLaunchUri.toString());
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final email = _emailController.text;
      final message = _messageController.text;

      final whatsappMessage = 'Name: $name\nEmail: $email\nMessage: $message';
      final encodedMessage = Uri.encodeComponent(whatsappMessage);
      final phoneNumber = _supportPhone.replaceAll('+', '');
      final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';

      _launchUrl(whatsappUrl);

      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force Dark Professional Theme
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final bgColor =
        isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor =
        isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final accentColor =
        isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final inputFill =
        isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('COMMUNICATION CENTER',
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
            Text('DIRECT CONTACT CHANNELS',
                style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 16),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border(left: BorderSide(color: accentColor, width: 4)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SUPPORT PROTOCOLS',
                      style: TextStyle(
                          color: textColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                      'Use these channels for critical support, partnerships, or reporting system anomalies. Response times may vary based on priority level.',
                      style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 12,
                          height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Grid of Contact Options
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildContactCard(
                    icon: Icons.email_outlined,
                    label: 'EMAIL UPLINK',
                    action: _launchEmail,
                    color: cardColor,
                    textColor: textColor,
                    accentColor: accentColor),
                _buildContactCard(
                    icon: Icons.call_outlined,
                    label: 'VOICE LINE',
                    action: _launchPhone,
                    color: cardColor,
                    textColor: textColor,
                    accentColor: Colors.green),
                _buildContactCard(
                    icon: Icons.chat_bubble_outline,
                    label: 'WHATSAPP',
                    action: () => _launchUrl(_whatsappUrl),
                    color: cardColor,
                    textColor: textColor,
                    accentColor: Colors.greenAccent),
                _buildContactCard(
                    icon: Icons.language,
                    label: 'WEB PORTAL',
                    action: () => _launchUrl(_websiteUrl),
                    color: cardColor,
                    textColor: textColor,
                    accentColor: Colors.purpleAccent),
              ],
            ),

            const SizedBox(height: 32),
            Text('SECURE TRANSMISSION FORM',
                style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 16),

            Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _buildTextField(
                        controller: _nameController,
                        hint: 'IDENTITY / NAME',
                        icon: Icons.person_outline,
                        bgColor: inputFill,
                        textColor: textColor,
                        borderColor: accentColor),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _emailController,
                        hint: 'RETURN ADDRESS (EMAIL)',
                        icon: Icons.alternate_email,
                        bgColor: inputFill,
                        textColor: textColor,
                        borderColor: accentColor),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _messageController,
                        hint: 'TRANSMISSION MESSAGE',
                        icon: Icons.short_text,
                        maxLines: 4,
                        bgColor: inputFill,
                        textColor: textColor,
                        borderColor: accentColor),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _submitForm,
                        icon: Icon(Icons.send, color: cardColor, size: 18),
                        label: Text('INITIATE TRANSMISSION',
                            style: TextStyle(
                                color: cardColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          elevation: 0,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            Center(
                child: Text('SECURE CONNECTION ESTABLISHED',
                    style: TextStyle(
                        color: Colors.green.withOpacity(0.5),
                        fontSize: 10,
                        letterSpacing: 2))),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
      {required IconData icon,
      required String label,
      required VoidCallback action,
      required Color color,
      required Color textColor,
      required Color accentColor}) {
    return InkWell(
      onTap: action,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: accentColor.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accentColor, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: borderColor.withOpacity(0.7), size: 18),
        hintText: hint,
        hintStyle: TextStyle(
            color: textColor.withOpacity(0.3),
            fontSize: 12,
            letterSpacing: 1.2),
        filled: true,
        fillColor: bgColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: borderColor, width: 1.5)),
      ),
      validator: (val) =>
          (val == null || val.isEmpty) ? 'FIELD REQUIRED' : null,
    );
  }
}
