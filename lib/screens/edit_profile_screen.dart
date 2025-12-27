import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/cloudinary_service.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? user = FirebaseAuth.instance.currentUser;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _emergencyController; // Authority: Designation
  late TextEditingController _aadharController; // Authority: ID

  bool _isSaving = false;
  bool _isAuthority = false;
  XFile? _profileImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isAuthority = widget.userData['role'] == 'authority';

    _nameController =
        TextEditingController(text: widget.userData['fullName'] ?? '');
    _emailController =
        TextEditingController(text: widget.userData['email'] ?? '');
    _phoneController =
        TextEditingController(text: widget.userData['phoneNumber'] ?? '');

    // For authority, reuse controllers but map to different fields
    _emergencyController = TextEditingController(
        text: _isAuthority
            ? (widget.userData['designation'] ?? '')
            : (widget.userData['emergencyContact'] ?? ''));

    _aadharController = TextEditingController(
        text: _isAuthority
            ? (widget.userData['authorityId'] ?? '')
            : (widget.userData['aadharNumber'] ?? ''));

    _profileImageUrl = widget.userData['profileImage'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyController.dispose();
    _aadharController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() => _profileImage = pickedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (user == null) return;

    setState(() => _isSaving = true);

    String? imageUrl = _profileImageUrl;

    try {
      if (_profileImage != null) {
        final response = await CloudinaryService.uploadFile(_profileImage!);
        final secureUrl =
            response != null ? CloudinaryService.getSecureUrl(response) : null;

        if (secureUrl != null) {
          imageUrl = secureUrl;
        } else {
          throw Exception('Image upload failed');
        }
      }

      final updateData = {
        'fullName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'profileImage': imageUrl,
      };

      if (_isAuthority) {
        updateData['designation'] = _emergencyController.text.trim();
        updateData['authorityId'] = _aadharController.text.trim();
      } else {
        updateData['emergencyContact'] = _emergencyController.text.trim();
        updateData['aadharNumber'] = _aadharController.text.trim();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile Updated Successfully'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine Theme Colors based on Role
    final isAuthorityMode = _isAuthority;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode || isAuthorityMode;

    Color bgColor = isAuthorityMode
        ? const Color(0xFF0F172A)
        : (isDarkMode ? const Color(0xFF0A0E21) : const Color(0xFFF5F5F5));
    Color cardColor = isAuthorityMode
        ? const Color(0xFF1E293B)
        : (isDarkMode ? const Color(0xFF1D2640) : Colors.white);
    Color textColor = isAuthorityMode
        ? const Color(0xFFF8FAFC)
        : (isDarkMode ? Colors.white : Colors.black87);
    Color labelColor = isAuthorityMode
        ? const Color(0xFF94A3B8)
        : (isDarkMode ? Colors.white70 : Colors.grey[600]!);
    Color accentColor =
        isAuthorityMode ? const Color(0xFFF59E0B) : Colors.deepPurple;
    Color fieldFill = isAuthorityMode
        ? const Color(0xFF0F172A)
        : (isDarkMode ? Colors.black12 : Colors.grey[50]!);
    Color iconColor =
        isAuthorityMode ? const Color(0xFF38BDF8) : Colors.deepPurple.shade300;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(isAuthorityMode ? 'OFFICIAL PROFILE' : 'Edit Profile',
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: isAuthorityMode ? 16 : 20,
                letterSpacing: isAuthorityMode ? 1.5 : 0)),
        backgroundColor: isAuthorityMode ? cardColor : Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: accentColor.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 2)
                          ]),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: cardColor,
                        backgroundImage: _profileImage != null
                            ? FileImage(File(_profileImage!.path))
                            : (_profileImageUrl != null &&
                                    _profileImageUrl!.isNotEmpty)
                                ? NetworkImage(_profileImageUrl!)
                                    as ImageProvider
                                : null,
                        child: (_profileImage == null &&
                                (_profileImageUrl == null ||
                                    _profileImageUrl!.isEmpty))
                            ? Icon(Icons.person, size: 60, color: labelColor)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _showImagePicker(context, isDarkMode),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: bgColor, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                  border: isAuthorityMode
                      ? Border.all(color: Colors.white10)
                      : null,
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      textColor: textColor,
                      labelColor: labelColor,
                      fillColor: fieldFill,
                      iconColor: iconColor,
                      borderColor: accentColor,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      readOnly: true,
                      textColor: textColor,
                      labelColor: labelColor,
                      fillColor: fieldFill,
                      iconColor: iconColor,
                      borderColor: accentColor,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textColor: textColor,
                      labelColor: labelColor,
                      fillColor: fieldFill,
                      iconColor: iconColor,
                      borderColor: accentColor,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _aadharController,
                      label: isAuthorityMode
                          ? 'Badge / Authority ID'
                          : 'Aadhaar Number',
                      icon: isAuthorityMode
                          ? Icons.badge_outlined
                          : Icons.credit_card,
                      textColor: textColor,
                      labelColor: labelColor,
                      fillColor: fieldFill,
                      iconColor: iconColor,
                      borderColor: accentColor,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _emergencyController,
                      label: isAuthorityMode
                          ? 'Official Designation'
                          : 'Emergency Contact',
                      icon: isAuthorityMode
                          ? Icons.work_outline
                          : Icons.contact_emergency_outlined,
                      keyboardType: isAuthorityMode
                          ? TextInputType.text
                          : TextInputType.phone,
                      textColor: textColor,
                      labelColor: labelColor,
                      fillColor: fieldFill,
                      iconColor: iconColor,
                      borderColor: accentColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'SAVE CHANGES',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  isAuthorityMode ? Colors.black : Colors.white,
                              letterSpacing: 1.2),
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
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    required Color textColor,
    required Color labelColor,
    required Color fillColor,
    required Color iconColor,
    required Color borderColor,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor),
        prefixIcon: Icon(icon, color: iconColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  void _showImagePicker(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Photo Library',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  _pickProfileImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text('Camera',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  _pickProfileImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
