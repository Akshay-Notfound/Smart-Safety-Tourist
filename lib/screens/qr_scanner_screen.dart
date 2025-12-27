import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'tourist_detail_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanCompleted = false;

  void _closeScreen() {
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _fetchTouristAndShowDetails(String userId) async {
    try {
      // Firestore madhun tourist cha data shodhu
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && mounted) {
        final touristData = doc.data() as Map<String, dynamic>;
        touristData['uid'] = userId; // Inject UID for updates

        // Also fetch location data for this tourist
        final locationDoc = await FirebaseFirestore.instance
            .collection('live_locations')
            .doc(userId)
            .get();

        Map<String, dynamic>? locationData;
        if (locationDoc.exists) {
          locationData = locationDoc.data() as Map<String, dynamic>;
        }

        // Tourist Detail Screen var janyasathi
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TouristDetailScreen(
              touristData: touristData,
              locationData: locationData,
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Tourist ID not found in database.'),
                backgroundColor: Colors.red),
          );
        }
        _closeScreen();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An error occurred: $e'),
              backgroundColor: Colors.red),
        );
      }
      _closeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Tourist ID'),
        backgroundColor: Colors.deepPurple.shade400,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (!_isScanCompleted) {
                final String code = capture.barcodes.first.rawValue ?? "---";
                setState(() {
                  _isScanCompleted =
                      true; // Jevha ek code scan hoil, tevha parat scan karu naye
                });
                _fetchTouristAndShowDetails(code);
              }
            },
          ),
          // Scanner sathi ek design overlay
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 4),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const Positioned(
            bottom: 50,
            child: Text(
              'Position QR code in frame to scan',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
