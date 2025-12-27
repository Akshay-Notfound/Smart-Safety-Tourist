import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_tourist_app/services/weather_service.dart';
import 'package:smart_tourist_app/services/safety_ml_service.dart';
import 'package:smart_tourist_app/models/weather_data_model.dart';

// Converted to StatefulWidget to handle async operations (Weather + Safety Score)
class TouristDetailScreen extends StatefulWidget {
  final Map<String, dynamic> touristData;
  final Map<String, dynamic>? locationData;

  const TouristDetailScreen({
    super.key,
    required this.touristData,
    this.locationData,
  });

  @override
  State<TouristDetailScreen> createState() => _TouristDetailScreenState();
}

class _TouristDetailScreenState extends State<TouristDetailScreen> {
  // State for Safety Score
  bool _isLoadingSafety = true;
  Map<String, dynamic> _safetyAnalysis = {};
  Hours? _remoteWeather;

  @override
  void initState() {
    super.initState();
    _calculateSafetyScore();
  }

  Future<void> _calculateSafetyScore() async {
    if (widget.locationData == null) {
      if (mounted) {
        setState(() {
          _isLoadingSafety = false;
          _safetyAnalysis = {
            'score': 50,
            'level': 'Unknown',
            'color': 0xFF9E9E9E,
            'details': 'No live location data available'
          };
        });
      }
      return;
    }

    try {
      final lat = widget.locationData!['latitude'] as double;
      final lon = widget.locationData!['longitude'] as double;
      final status = widget.locationData!['status'] as String? ?? 'inactive';

      // Fetch weather specifically for the tourist's location
      // Note: We use a fresh repository instance or service here ideally,
      // but for now we can leverage the existing WeatherService logic
      // or create a lightweight fetch if needed.
      // To keep it clean, let's use the Provider but we need to be careful not to override global state
      // if the provider is singleton.
      // Actually, WeatherService updates its state. We shouldn't use the global provider if we want isolated data.
      // So we will instantiate a temporary service/repo logic here.

      final weatherService = WeatherService();
      await weatherService.fetchWeatherData(lat, lon);

      if (mounted) {
        setState(() {
          _remoteWeather = weatherService.currentHour;
          _safetyAnalysis = SafetyMLService.analyzeSafety(
            currentWeather: _remoteWeather,
            locationStatus: status,
          );
          _isLoadingSafety = false;
        });
      }
    } catch (e) {
      print('Error calculating safety score: $e');
      if (mounted) {
        setState(() {
          _isLoadingSafety = false;
          _safetyAnalysis = {
            'score': 0,
            'level': 'Error',
            'color': 0xFF9E9E9E,
            'details': 'Failed to analyze conditions'
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var locationData = widget.locationData;
    var touristData = widget.touristData; // Convenience alias

    return Scaffold(
      appBar: AppBar(
        title: Text(touristData['fullName'] ?? 'Tourist Details'),
        backgroundColor: const Color(0xFF1D2640),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (locationData != null)
              _buildMapContainer(
                locationData['latitude'],
                locationData['longitude'],
                locationData['status'] ?? 'unknown',
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationCard(context),
                  const SizedBox(height: 16),
                  _buildSafetyScoreCard(), // New Safety Card
                  const SizedBox(height: 16),
                  const Text('Personal Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildDetailRow(
                              icon: Icons.email,
                              title: 'Email',
                              value: touristData['email'] ?? 'N/A'),
                          const Divider(),
                          _buildDetailRow(
                              icon: Icons.phone,
                              title: 'Phone',
                              value: touristData['phoneNumber'] ?? 'N/A'),
                          const Divider(),
                          _buildDetailRow(
                              icon: Icons.badge,
                              title: 'Aadhaar',
                              value: touristData['aadharNumber'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Emergency Contacts',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildEmergencyContactsSection(context),
                  const SizedBox(height: 20),
                  const Text('ID Documents',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildDocumentsSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    if (widget.locationData == null) {
      return const SizedBox.shrink(); // Using proper null handling
    }
    // We can reuse the existing logic but accessed via widget.locationData
    return _buildLocationStatusInfo(
        widget.locationData!['status'] ?? 'unknown');
  }

  // --- Helper Methods (Moved from stateless to state class) ---

  Widget _buildMapContainer(double lat, double lon, String status) {
    if (!_checkGoogleMapsAvailability()) {
      return _buildMapFallback(lat, lon, status);
    }

    return SizedBox(
      height: 250,
      width: double.infinity,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(lat, lon),
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('tourist_loc'),
            position: LatLng(lat, lon),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(_getMarkerColor(status)),
          ),
        },
        myLocationEnabled: false,
        zoomControlsEnabled: false,
      ),
    );
  }

  bool _checkGoogleMapsAvailability() {
    // Basic check - in a real app might verify API key presence or platform
    return true;
  }

  Widget _buildMapFallback(double lat, double lon, String status) {
    return Container(
      height: 250,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on,
                size: 50, color: _getMarkerColorHTML(status)),
            const SizedBox(height: 8),
            Text('Lat: $lat, Lon: $lon'),
            Text('Status: $status',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Replaced with simple color getter since BitmapDescriptor is distinct
  Color _getMarkerColorHTML(String status) {
    switch (status) {
      case 'panic':
        return Colors.red;
      case 'tracking':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  double _getMarkerColor(String status) {
    switch (status) {
      case 'panic':
        return BitmapDescriptor.hueRed;
      case 'tracking':
        return BitmapDescriptor.hueGreen;
      default:
        return BitmapDescriptor.hueOrange;
    }
  }

  Widget _buildLocationStatusInfo(String status) {
    IconData icon;
    Color color;
    String text;

    switch (status) {
      case 'panic':
        icon = Icons.warning_amber_rounded;
        color = Colors.red;
        text = 'PANIC ALERT ACTIVE';
        break;
      case 'tracking':
        icon = Icons.my_location;
        color = Colors.green;
        text = 'Live Tracking Active';
        break;
      default:
        icon = Icons.location_off;
        color = Colors.grey;
        text = 'Location Inactive';
    }

    return Card(
      color: color.withOpacity(0.1),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        subtitle:
            HelperText(status), // Helper widget for simple conditional text
      ),
    );
  }

  Widget HelperText(String status) {
    if (status == 'panic')
      return const Text('User has triggered emergency alert');
    if (status == 'tracking')
      return const Text('Location updating in real-time');
    return const Text('Last known location shown');
  }

  Widget _buildSafetyScoreCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AI Safety Analysis',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (_isLoadingSafety)
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Color(_safetyAnalysis['color'] ?? 0xFF9E9E9E),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${_safetyAnalysis['score'] ?? 0}/100',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
              ],
            ),
            const SizedBox(height: 12),
            if (!_isLoadingSafety) ...[
              Row(
                children: [
                  Icon(Icons.shield,
                      color: Color(_safetyAnalysis['color'] ?? 0xFF9E9E9E)),
                  const SizedBox(width: 8),
                  Text(_safetyAnalysis['level'] ?? 'Analyzing...',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              Color(_safetyAnalysis['color'] ?? 0xFF9E9E9E))),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _safetyAnalysis['details'] ?? 'Assessing risks...',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ] else
              const Text('Analyzing weather and location data...',
                  style: TextStyle(color: Colors.grey))
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactsSection(BuildContext context) {
    // Assuming 'emergencyContacts' is a List in user data
    if (widget.touristData['emergencyContacts'] == null) {
      return const Text('No emergency contacts listed.',
          style: TextStyle(color: Colors.grey));
    }

    // Logic to parse different formats if necessary, simplified for now
    List<dynamic> contacts = widget.touristData['emergencyContacts'] is List
        ? widget.touristData['emergencyContacts']
        : [];

    if (contacts.isEmpty) {
      return const Text('No emergency contacts listed.',
          style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: contacts.map<Widget>((contact) {
        // Handle if contact is a Map or just a String (simple/complex structures)
        String name = 'Contact';
        String phone = '';
        if (contact is Map) {
          name = contact['name'] ?? 'Contact';
          phone = contact['number'] ?? '';
        } else {
          // Fallback
          phone = contact.toString();
        }

        return Card(
          child: ListTile(
            leading: const Icon(Icons.phone_in_talk, color: Colors.redAccent),
            title: Text(name),
            subtitle: Text(phone),
            trailing: IconButton(
              icon: const Icon(Icons.call, color: Colors.green),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Simulating call to $phone')));
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDocumentsSection(BuildContext context) {
    List<dynamic> documents = widget.touristData['documents'] ?? [];

    if (documents.isEmpty) {
      return const Center(child: Text('No documents uploaded.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> document = Map.from(documents[index] as Map);
        bool isVerified = document['verified'] == true;
        bool isRejected = document['rejected'] == true && !isVerified;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.description, color: Colors.blueAccent),
            title: Text(document['name'] ?? 'Document ${index + 1}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${document['type'] ?? 'ID'}'),
                Text('Date: ${_formatDate(document['uploadedAt'])}'),
                const SizedBox(height: 4),
                if (isVerified)
                  const Text('Verified (Real)',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold))
                else if (isRejected)
                  const Text('Marked as Fake/Invalid',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold))
                else
                  const Text('Pending Verification',
                      style: TextStyle(color: Colors.orange)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => _viewDocument(document['url'], context),
                ),
                // Verification Actions
                if (!isVerified)
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    tooltip: 'Mark as Real',
                    onPressed: () => _verifyDocument(context, index, true),
                  ),
                if (!isRejected)
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    tooltip: 'Mark as Fake',
                    onPressed: () => _verifyDocument(context, index, false),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _verifyDocument(
      BuildContext context, int index, bool isValid) async {
    try {
      // Create a copy of the documents list
      List<dynamic> documents =
          List.from(widget.touristData['documents'] ?? []);

      if (index >= 0 && index < documents.length) {
        // Update the specific document
        Map<String, dynamic> doc = Map.from(documents[index] as Map);
        doc['verified'] = isValid;
        doc['rejected'] = !isValid;
        doc['verifiedAt'] = Timestamp.now();
        documents[index] = doc;

        // Update Firestore
        // Update Firestore
        final uid = widget.touristData['uid'];
        if (uid != null) {
          final userRef =
              FirebaseFirestore.instance.collection('users').doc(uid);

          Color snackBarColor = isValid ? Colors.green : Colors.red;
          String snackBarMessage =
              isValid ? 'Document marked as Real' : 'Document marked as Fake';

          // 1. Update documents array
          await userRef.update({'documents': documents});

          // 2. Add Notification
          await userRef.collection('notifications').add({
            'title': isValid
                ? 'Document Approved'
                : 'Action Required: Document Rejected',
            'message': isValid
                ? 'Your document has been verified by the authorities.'
                : 'A document provided by you has been marked as invalid/fake. Please review immediately.',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': isValid ? 'success' : 'alert',
          });

          // 3. Flag user if document is fake
          if (!isValid) {
            await userRef.update({
              'isFlagged': true,
              'documentStatus': 'rejected',
            });
            snackBarMessage += '. User flagged.';
          } else {
            // Optional: Check if all documents are now valid and remove flag?
            // For now, let's just assume valid updates don't Auto-Unflag to be safe
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(snackBarMessage),
                backgroundColor: snackBarColor,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Error: User ID not found, cannot save changes')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating document: $e')),
        );
      }
    }
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

  void _viewDocument(String url, BuildContext context) {
    if (url.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('View Document',
                style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                url,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 50),
                    SizedBox(height: 16),
                    Text('Failed to load image',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      {required IconData icon, required String title, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ],
    );
  }
}
