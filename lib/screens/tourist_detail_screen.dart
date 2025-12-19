import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TouristDetailScreen extends StatelessWidget {
  final Map<String, dynamic> touristData;
  final Map<String, dynamic>? locationData;

  const TouristDetailScreen(
      {super.key, required this.touristData, this.locationData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tourist Details'),
        backgroundColor: Colors.deepPurple.shade400,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: touristData['profileImage'] != null &&
                                touristData['profileImage']
                                    .toString()
                                    .isNotEmpty
                            ? NetworkImage(touristData['profileImage'])
                            : null,
                        child: touristData['profileImage'] != null &&
                                touristData['profileImage']
                                    .toString()
                                    .isNotEmpty
                            ? null
                            : Text(
                                touristData['fullName']?[0] ?? 'T',
                                style: const TextStyle(fontSize: 24),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        touristData['fullName'] ?? 'No Name Provided',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        touristData['email'] ?? 'No Email',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ),
                    const Divider(height: 32),
                    _buildDetailRow(
                      icon: Icons.phone,
                      title: 'Phone Number',
                      value: touristData['phoneNumber'] ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.contact_phone_outlined,
                      title: 'Emergency Contact',
                      value: touristData['emergencyContact'] ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.badge_outlined,
                      title: 'Aadhaar / Passport No.',
                      value: touristData['aadharNumber'] ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.shield_outlined,
                      title: 'Current Safety Score',
                      value: _getSafetyScoreText(touristData),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Add the map view card for tourist location
            _buildLocationCard(context),
            const SizedBox(height: 16),
            // Add emergency contacts section
            _buildEmergencyContactsSection(context),
            const SizedBox(height: 16),
            // Add documents section
            _buildDocumentsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    // If locationData is provided, show the map
    if (locationData != null &&
        locationData!['latitude'] != null &&
        locationData!['longitude'] != null) {
      final lat = locationData!['latitude'];
      final lon = locationData!['longitude'];
      final status = locationData!['status'] ?? 'tracking';

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on,
                      color: Colors.deepPurple.shade300, size: 28),
                  const SizedBox(width: 16),
                  const Text(
                    'Current Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Wrap GoogleMap in a try-catch using a FutureBuilder to handle errors
              _buildMapContainer(lat, lon, status),
              const SizedBox(height: 16),
              _buildLocationStatusInfo(status),
            ],
          ),
        ),
      );
    } else {
      // If no location data, show a message
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_off,
                      color: Colors.grey.shade400, size: 28),
                  const SizedBox(width: 16),
                  const Text(
                    'Location Tracking',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'This tourist is not currently sharing their location.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMapContainer(double lat, double lon, String status) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: FutureBuilder<bool>(
        future: _checkGoogleMapsAvailability(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data == true) {
            // Google Maps is available, show the map
            try {
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(lat, lon),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('tourist_location'),
                    position: LatLng(lat, lon),
                    icon: _getMarkerIcon(status),
                    infoWindow: InfoWindow(
                      title: touristData['fullName'] ?? 'Tourist',
                      snippet: 'Status: ${_getStatusText(status)}',
                    ),
                  ),
                },
                mapType: MapType.normal,
                zoomControlsEnabled: true,
                myLocationButtonEnabled: false,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
              );
            } catch (e) {
              // If Google Maps fails, show fallback
              return _buildMapFallback(lat, lon, status);
            }
          } else {
            // Google Maps not available, show fallback
            return _buildMapFallback(lat, lon, status);
          }
        },
      ),
    );
  }

  Future<bool> _checkGoogleMapsAvailability() async {
    try {
      // This is a simple check - in a real app you might want to do a more thorough check
      return true;
    } catch (e) {
      return false;
    }
  }

  Widget _buildMapFallback(double lat, double lon, String status) {
    // Show a simple card with location information instead of the map
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on,
            size: 48,
            color: _getMarkerColor(status),
          ),
          const SizedBox(height: 16),
          Text(
            'Location: ${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Status: ${_getStatusText(status)}',
            style: TextStyle(
              fontSize: 14,
              color: _getMarkerColor(status),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMarkerColor(String status) {
    if (status == 'panic') {
      return Colors.red;
    } else {
      final timestamp = (locationData!['timestamp'] as Timestamp?)?.toDate();
      if (timestamp != null &&
          DateTime.now().difference(timestamp).inMinutes > 15) {
        return Colors.orange;
      } else {
        return Colors.green;
      }
    }
  }

  BitmapDescriptor _getMarkerIcon(String status) {
    if (status == 'panic') {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else {
      final timestamp = (locationData!['timestamp'] as Timestamp?)?.toDate();
      if (timestamp != null &&
          DateTime.now().difference(timestamp).inMinutes > 15) {
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow);
      } else {
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'panic':
        return 'PANIC ALERT!';
      case 'tracking':
        final timestamp = (locationData!['timestamp'] as Timestamp?)?.toDate();
        if (timestamp != null &&
            DateTime.now().difference(timestamp).inMinutes > 15) {
          return 'Inactive (Location Off)';
        }
        return 'Live Tracking On';
      default:
        return status;
    }
  }

  Widget _buildLocationStatusInfo(String status) {
    IconData icon;
    Color color;
    String text;

    switch (status) {
      case 'panic':
        icon = Icons.error;
        color = Colors.red;
        text = 'PANIC ALERT! Tourist requires immediate assistance.';
        break;
      case 'tracking':
        final timestamp = (locationData!['timestamp'] as Timestamp?)?.toDate();
        if (timestamp != null &&
            DateTime.now().difference(timestamp).inMinutes > 15) {
          icon = Icons.warning;
          color = Colors.orange;
          text =
              'Location tracking is enabled but location data is stale (older than 15 minutes).';
        } else {
          icon = Icons.check_circle;
          color = Colors.green;
          text = 'Location tracking is active and up to date.';
        }
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
        text = 'Location status: $status';
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyContactsSection(BuildContext context) {
    final List<dynamic>? emergencyContacts =
        touristData['emergencyContacts'] as List<dynamic>?;

    if (emergencyContacts == null || emergencyContacts.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          title: const Text(
            'Emergency Contacts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No emergency contacts available for this tourist.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Contact these numbers in order if the tourist cannot be reached directly:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: emergencyContacts.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final contact =
                        emergencyContacts[index] as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple.shade100,
                        child: Text(
                          contact['name']?[0] ?? '?',
                          style: TextStyle(color: Colors.deepPurple.shade800),
                        ),
                      ),
                      title: Text(contact['name'] ?? 'No Name'),
                      subtitle: Text(contact['phone'] ?? 'No Phone'),
                      trailing: IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () {
                          // In a real app, this would initiate a phone call
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'In a real app, this would initiate a phone call'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(BuildContext context) {
    final List<dynamic>? documents = touristData['documents'] as List<dynamic>?;

    if (documents == null || documents.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          title: const Text(
            'ID Documents',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No ID documents uploaded by this tourist.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text(
          'ID Documents',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Government-issued ID documents uploaded by the tourist:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: documents.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final document = documents[index] as Map<String, dynamic>;
                    return ListTile(
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
                      trailing: IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () =>
                            _viewDocument(document['url'], context),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
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

  void _viewDocument(String url, BuildContext context) {
    // In a real app, you would open the image in a viewer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('In a real app, this would open: $url'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getSafetyScoreText(Map<String, dynamic> touristData) {
    // In a real implementation, this would fetch the actual safety score from the database
    // For now, we'll return a placeholder that indicates this is dynamic data
    return 'View live safety score in tourist app';
  }

  // Mahiti dakhavnyasathi helper widget
  Widget _buildDetailRow(
      {required IconData icon, required String title, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.deepPurple.shade300, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
