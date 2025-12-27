import 'package:flutter/material.dart';
import 'super_admin_dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SuperAdminLoginScreen extends StatefulWidget {
  const SuperAdminLoginScreen({super.key});

  @override
  State<SuperAdminLoginScreen> createState() => _SuperAdminLoginScreenState();
}

class _SuperAdminLoginScreenState extends State<SuperAdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final Color _executiveBg = const Color(0xFF020617); // Deep Navy
  final Color _executiveCard = const Color(0xFF0F172A); // Slate 900
  final Color _goldAccent = const Color(0xFFF59E0B); // Gold
  final Color _textPlatinum = const Color(0xFFE2E8F0); // Platinum

  bool _isLoading = false;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Hardcoded credentials for Super Admin Check (Client Side Security level 1)
      if (_emailController.text.trim() == 'admin@gmail.com' &&
          _passwordController.text.trim() == 'admin123') {
        try {
          // Attempt to sign in to Firebase
          UserCredential userCred;
          try {
            userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: 'admin@gmail.com',
              password: 'admin123',
            );
          } on FirebaseAuthException catch (e) {
            // First time admin creation
            if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
              userCred =
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: 'admin@gmail.com',
                password: 'admin123',
              );
            } else {
              rethrow;
            }
          }

          // Ensure Admin Record Exists in Firestore (Vital for Security Rules)
          if (userCred.user != null) {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userCred.user!.uid)
                .get();
            if (!userDoc.exists) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userCred.user!.uid)
                  .set({
                'fullName': 'Super Administrator',
                'email': 'admin@gmail.com',
                'role': 'authority', // Or 'super_admin' if supported
                'department': 'CENTRAL COMMAND',
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
          }

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const SuperAdminDashboardScreen()),
            );
          }
        } catch (e) {
          if (mounted) {
            _showError('AUTHENTICATION FAILED: $e');
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        _showError('INVALID EXECUTIVE CREDENTIALS');
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red.shade900,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _executiveBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _goldAccent, width: 2),
                  // color: _executiveCard,
                  boxShadow: [
                    BoxShadow(
                        color: _goldAccent.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ],
                ),
                child: Icon(Icons.shield, size: 60, color: _goldAccent),
              ),
              const SizedBox(height: 24),
              Text(
                'EXECUTIVE LOGIN',
                style: TextStyle(
                    color: _textPlatinum,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3),
              ),
              const SizedBox(height: 8),
              Text(
                'SUPER ADMIN PROTOCOL',
                style: TextStyle(
                    color: _goldAccent, fontSize: 10, letterSpacing: 2),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _executiveCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                          controller: _emailController,
                          label: 'ADMIN ID',
                          icon: Icons.person_outline),
                      const SizedBox(height: 20),
                      _buildTextField(
                          controller: _passwordController,
                          label: 'SECURE KEY',
                          icon: Icons.lock_outline,
                          isPassword: true),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _goldAccent,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.black),
                                )
                              : const Text(
                                  'INITIATE SESSION',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: _textPlatinum),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _textPlatinum.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: _goldAccent.withOpacity(0.8)),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white10),
            borderRadius: BorderRadius.circular(4)),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: _goldAccent),
            borderRadius: BorderRadius.circular(4)),
        filled: true,
        fillColor: const Color(0xFF020617).withOpacity(0.5),
      ),
      validator: (value) => value!.isEmpty ? 'FIELD REQUIRED' : null,
    );
  }
}
