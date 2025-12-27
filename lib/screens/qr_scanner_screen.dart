import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'tourist_detail_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanCompleted = false;
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _closeScreen() {
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _fetchTouristAndShowDetails(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && mounted) {
        final touristData = doc.data() as Map<String, dynamic>;
        touristData['uid'] = userId;

        final locationDoc = await FirebaseFirestore.instance
            .collection('live_locations')
            .doc(userId)
            .get();

        Map<String, dynamic>? locationData;
        if (locationDoc.exists) {
          locationData = locationDoc.data() as Map<String, dynamic>;
        }

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
                content: Text('ID Unknown. Access Denied.'),
                backgroundColor: Colors.red),
          );
        }
        _closeScreen();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('System Error: $e'), backgroundColor: Colors.red),
        );
      }
      _closeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (!_isScanCompleted) {
                final String code = capture.barcodes.first.rawValue ?? "---";
                setState(() {
                  _isScanCompleted = true;
                });
                _fetchTouristAndShowDetails(code);
              }
            },
          ),

          // Dark Overlay for "Focus" effect
          ColorFiltered(
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.6), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstIn,
                  ),
                ),
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // HUD Overlay
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Positioned(
            top: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.8), // Slate 900
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF38BDF8), width: 1) // Sky 400
                  ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.qr_code_scanner,
                      color: Color(0xFF38BDF8), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'SCANNER ACTIVE',
                    style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5),
                  ),
                ],
              ),
            ),
          ),

          // Animated Scanner Line
          if (!_isScanCompleted)
            AnimatedBuilder(
              animation: _scannerController,
              builder: (context, child) {
                return Positioned(
                  top: MediaQuery.of(context).size.height / 2 -
                      140 +
                      (280 * _scannerController.value),
                  child: Container(
                    width: 280,
                    height: 2,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 2)
                      ],
                      color: const Color(0xFFF59E0B), // Amber 500
                    ),
                  ),
                );
              },
            ),

          // Viewfinder Corners
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCorner(0),
                      _buildCorner(1),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCorner(2),
                      _buildCorner(3),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Positioned(
            bottom: 80,
            child: Text(
              'ALIGN CODE WITHIN FRAME',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(int index) {
    return RotatedBox(
      quarterTurns: index,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
            border: Border(
          top: BorderSide(color: Color(0xFFF59E0B), width: 3),
          left: BorderSide(color: Color(0xFFF59E0B), width: 3),
        )),
      ),
    );
  }
}
