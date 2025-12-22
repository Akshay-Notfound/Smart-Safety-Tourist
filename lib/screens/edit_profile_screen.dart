import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb, Uint8List
import 'dart:typed_data'; // For Uint8List
import '../services/cloudinary_service.dart';

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
  late TextEditingController _emergencyController;
  late TextEditingController _aadharController;

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
        final length = await pickedFile.length();
        print('Image picked: ${pickedFile.path}, Size: $length bytes');
        setState(() {
          _profileImage = pickedFile;
        });

        // Show a preview message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image selected. Tap Save to upload.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        // User cancelled the picker
        print('No image selected');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image selected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return _profileImageUrl;

    try {
      final response = await CloudinaryService.uploadFile(_profileImage!);

      if (response != null) {
        final secureUrl = CloudinaryService.getSecureUrl(response);
        if (secureUrl != null) {
          return secureUrl;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload profile image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error uploading profile image: $e');
      if (mounted) {
        // Extract error message if it's a Cloudinary error
        String errorMessage = 'Error uploading profile image';
        if (e.toString().contains('Upload failed:')) {
          // Try to parse the JSON error from Cloudinary if possible, or just show the status
          if (e.toString().contains('"message":')) {
            final match =
                RegExp(r'"message":"([^"]+)"').firstMatch(e.toString());
            if (match != null) {
              errorMessage = 'Upload failed: ${match.group(1)}';
            } else {
              errorMessage = e.toString().replaceAll('Exception: ', '');
            }
          } else {
            errorMessage = e.toString().replaceAll('Exception: ', '');
          }
        } else {
          errorMessage = 'Error: $e';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Upload profile image if selected
      String? profileImageUrl = _profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _uploadProfileImage();
        if (profileImageUrl == null) {
          // If image upload failed, don't save the profile
          return;
        }
      }

      // Prepare update data
      final updateData = {
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
      };

      if (_isAuthority) {
        updateData['designation'] = _emergencyController.text.trim();
        updateData['authorityId'] = _aadharController.text.trim();
      } else {
        updateData['emergencyContact'] = _emergencyController.text.trim();
        updateData['aadharNumber'] = _aadharController.text.trim();
      }

      // Add profile image URL if available
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        updateData['profileImage'] = profileImageUrl;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to previous screen
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.deepPurple.shade400,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isAuthority ? 'Authority Profile' : 'Personal Information',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Update your profile details',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _isSaving ? null : _showImagePickerOptions,
                      child: ClipOval(
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: _profileImage != null
                              ? FutureBuilder<Uint8List>(
                                  future: _profileImage!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                            ConnectionState.done &&
                                        snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Center(
                                              child: Icon(Icons.error,
                                                  color: Colors.red));
                                        },
                                      );
                                    } else {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                  },
                                )
                              : (_profileImageUrl != null &&
                                      _profileImageUrl!.isNotEmpty
                                  ? Image.network(
                                      _profileImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Center(
                                          child: Text(
                                            _nameController.text.isNotEmpty
                                                ? _nameController.text[0]
                                                    .toUpperCase()
                                                : 'T',
                                            style: TextStyle(
                                              fontSize: 32,
                                              color: Colors.deepPurple.shade800,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Center(
                                      child: Text(
                                        _nameController.text.isNotEmpty
                                            ? _nameController.text[0]
                                                .toUpperCase()
                                            : 'T',
                                        style: TextStyle(
                                          fontSize: 32,
                                          color: Colors.deepPurple.shade800,
                                        ),
                                      ),
                                    )),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isSaving ? null : _showImagePickerOptions,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Debug information
              if (_profileImage != null)
                const Text(
                  'Local image selected',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                )
              else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                const Text(
                  'Existing profile image loaded',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                )
              else
                const Text(
                  'No profile image set',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Number Field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Emergency Contact / Designation Field
              TextFormField(
                controller: _emergencyController,
                decoration: InputDecoration(
                  labelText: _isAuthority
                      ? 'Designation / Division'
                      : 'Emergency Contact',
                  prefixIcon: Icon(_isAuthority
                      ? Icons.work_outline
                      : Icons.contact_phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType:
                    _isAuthority ? TextInputType.text : TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _isAuthority
                        ? 'Please enter designation'
                        : 'Please enter emergency contact';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Aadhaar / Authority ID Field
              TextFormField(
                controller: _aadharController,
                decoration: InputDecoration(
                  labelText: _isAuthority
                      ? 'Authority Badge ID'
                      : 'Aadhaar / Passport Number',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.text, // Allow text for IDs
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
