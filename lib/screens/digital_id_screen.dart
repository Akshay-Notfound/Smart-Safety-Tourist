import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// !! ERROR THIK KELA !! - package. aivaji package: kele ahe
import 'package:qr_flutter/qr_flutter.dart';

class DigitalIdScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const DigitalIdScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    // User cha unique Firebase ID gheu, jo konihi guess karu shakat nahi.
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    // Ha apla "Blockchain" reference ahe. Ha ek unique, non-guessable ID ahe
    // jo kahihi personal mahiti ughad karat nahi, transaction hash sarkha.
    final String blockchainData = userId ?? "invalid_user_id";

    return Scaffold(
      appBar: AppBar(
        title: Text('Digital Tourist ID'),
        backgroundColor: Colors.deepPurple.shade400,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.deepPurple.shade100,
                    child: Icon(
                      Icons.person_outline,
                      size: 50,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    userData['fullName'] ?? 'N/A',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'VERIFIED TOURIST',
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5),
                  ),
                  Divider(height: 30),
                  // Aata QR code madhye fakt secure ID ahe
                  QrImageView(
                    data: blockchainData,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Present this secure QR to authorized personnel for verification.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 8),
                  // User la tyacha unique ID dakhavu (thoda bhag)
                  Text(
                    'ID: ${userId?.substring(0, 12)}...',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  SizedBox(height: 16),
                  Chip(
                    label: Text('Valid for this trip only'),
                    backgroundColor: Colors.amber.shade100,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

