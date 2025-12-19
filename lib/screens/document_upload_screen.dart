// import 'dart:io'; // Removed for Web compatibility
import 'dart:async';
// import 'dart:io' show InternetAddress; // Removed for Web compatibility
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

import 'aadhar_detail_screen.dart';

// Enum for storage service options
enum StorageService { cloudinary, firebase }

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  bool _isUploading = false;
  bool _useFirebaseStorage = false; // Toggle for storage service
  final ImagePicker _picker = ImagePicker();
  final _aadharController = TextEditingController();
  String? _aadharNumber;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
    _fetchAadharNumber();
  }

  Future<void> _fetchAadharNumber() async {
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (userDoc.exists && userDoc.data()!.containsKey('aadharNumber')) {
        setState(() {
          _aadharNumber = userDoc.data()!['aadharNumber'];
          _aadharController.text = _aadharNumber ?? '';
        });
      }
    } catch (e) {
      print('Error fetching Aadhar number: $e');
    }
  }

  Future<void> _fetchDocuments() async {
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (userDoc.exists && userDoc.data()!.containsKey('documents')) {
        setState(() {
          _documents =
              List<Map<String, dynamic>>.from(userDoc.data()!['documents']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } on TimeoutException catch (e) {
      print('Timeout error fetching documents: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request timed out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching documents: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading documents. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateDocumentsInFirestore() async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'documents': _documents,
      }, SetOptions(merge: true));
    } on TimeoutException catch (e) {
      print('Timeout error updating documents: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request timed out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error updating documents: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving documents. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAadharNumber() async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'aadharNumber': _aadharController.text.trim(),
      }, SetOptions(merge: true));

      setState(() {
        _aadharNumber = _aadharController.text.trim();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aadhaar number saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving Aadhar number: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving Aadhaar number. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadDocument() async {
    if (_useFirebaseStorage) {
      await _pickAndUploadDocumentWithFirebase();
    } else {
      await _pickAndUploadDocumentWithCloudinary();
    }
  }

  Future<void> _pickAndUploadDocumentWithCloudinary() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _isUploading = true;
        });

        // Upload to Cloudinary
        final response = await CloudinaryService.uploadFile(image);

        if (response != null) {
          final downloadUrl = CloudinaryService.getSecureUrl(response);
          if (downloadUrl != null) {
            // Add to documents list
            final newDocument = {
              'name': image.name,
              'url': downloadUrl,
              'uploadedAt': FieldValue.serverTimestamp(),
              'type': 'ID Document',
            };

            setState(() {
              _documents.add(newDocument);
              _isUploading = false;
            });

            // Save to Firestore
            await _updateDocumentsInFirestore();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document uploaded successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            _handleUploadError(
                'Failed to get download URL from Cloudinary. Please try again.');
          }
        } else {
          _handleUploadError(
              'Failed to upload document to Cloudinary. Please try again.');
        }
      }
    } on TimeoutException catch (e) {
      print('Timeout during document upload: $e');
      _handleUploadError(
          'Upload timed out. Please check your internet connection and try again.');
    } catch (e) {
      print('Error uploading document: $e');
      _handleUploadError('An error occurred during upload. Please try again.');
    }
  }

  Future<void> _pickAndUploadDocumentWithFirebase() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _isUploading = true;
        });

        // Temporary Web workaround: Firebase upload disabled
        _handleUploadError(
            'Firebase upload not supported on Web yet. Please use Cloudinary.');
        return;

        /*
        // Upload to Firebase Storage
        final file = File(image.path);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final downloadUrl =
            await FirebaseStorageService.uploadDocument(file, fileName);

        if (downloadUrl != null) {
          // Add to documents list
          final newDocument = {
            'name': image.name,
            'url': downloadUrl,
            'uploadedAt': FieldValue.serverTimestamp(),
            'type': 'ID Document',
          };

          setState(() {
            _documents.add(newDocument);
            _isUploading = false;
          });

          // Save to Firestore
          await _updateDocumentsInFirestore();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Document uploaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          _handleUploadError(
              'Failed to upload document to Firebase Storage. Please try again.');
        }
        */
      }
    } on TimeoutException catch (e) {
      print('Timeout during document upload: $e');
      _handleUploadError(
          'Upload timed out. Please check your internet connection and try again.');
    } catch (e) {
      print('Error uploading document: $e');
      _handleUploadError('An error occurred during upload. Please try again.');
    }
  }

  void _handleUploadError([String message = 'Error uploading document']) {
    setState(() {
      _isUploading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteDocument(int index) {
    setState(() {
      _documents.removeAt(index);
    });

    _updateDocumentsInFirestore().then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }).catchError((error) {
      print('Error after deleting document: $error');
      // Re-add the document if the update failed
      // In a real app, you might want to handle this more gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error removing document. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Upload'),
        backgroundColor: Colors.deepPurple.shade400,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              setState(() {
                _useFirebaseStorage = result == 'firebase';
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'cloudinary',
                child: Text('Use Cloudinary'),
              ),
              const PopupMenuItem<String>(
                value: 'firebase',
                child: Text('Use Firebase Storage'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upload ID Documents',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload government-issued ID documents for verification',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Aadhaar number input section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aadhaar / Passport Number',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Enter your Aadhaar or Passport number for verification',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _aadharController,
                            decoration: InputDecoration(
                              labelText: 'Aadhaar / Passport Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.badge_outlined),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _saveAadharNumber,
                              icon: const Icon(Icons.save),
                              label: const Text('Save Aadhaar Number'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                            ),
                          ),
                          if (_aadharNumber != null &&
                              _aadharNumber!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Saved: $_aadharNumber',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AadharDetailScreen(
                                        userId: user!.uid,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.visibility),
                                label: const Text('View Aadhaar Details'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Upload button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickAndUploadDocument,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.upload_file),
                      label: Text(
                          _isUploading ? 'Uploading...' : 'Upload Document'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Documents list
                  const Text(
                    'Uploaded Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _documents.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.document_scanner_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No documents uploaded yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Upload your ID documents for verification',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _documents.length,
                            itemBuilder: (context, index) {
                              final document = _documents[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.description,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  title: Text(document['type'] ?? 'Document'),
                                  subtitle: Text(
                                    document['uploadedAt'] != null
                                        ? 'Uploaded: ${_formatDate(document['uploadedAt'])}'
                                        : 'Uploaded recently',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility,
                                            color: Colors.blue),
                                        onPressed: () =>
                                            _viewDocument(document['url']),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => _deleteDocument(index),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  void _viewDocument(String url) {
    // In a real app, you would open the image in a viewer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('In a real app, this would open: $url'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
