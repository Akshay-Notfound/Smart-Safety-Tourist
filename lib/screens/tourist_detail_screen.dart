import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_tourist_app/services/weather_service.dart';
import 'package:smart_tourist_app/services/safety_ml_service.dart';
import 'package:smart_tourist_app/models/weather_data_model.dart';

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
  // Theme Constants
  final Color _bgColor = const Color(0xFF0F172A);
  final Color _cardColor = const Color(0xFF1E293B);
  final Color _primaryText = const Color(0xFFF8FAFC);
  final Color _secondaryText = const Color(0xFF94A3B8);
  final Color _accentColor = const Color(0xFF38BDF8); // Sky Blue for info
  final Color _dangerColor = const Color(0xFFEF4444);
  final Color _successColor = const Color(0xFF10B981);
  final Color _warningColor = const Color(0xFFF59E0B);

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
            'level': 'UNKNOWN',
            'color': 0xFF94A3B8,
            'details': 'NO LIVE LOCATION DATA'
          };
        });
      }
      return;
    }

    try {
      final lat = widget.locationData!['latitude'] as double;
      final lon = widget.locationData!['longitude'] as double;
      final status = widget.locationData!['status'] as String? ?? 'inactive';

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
      if (mounted) {
        setState(() {
          _isLoadingSafety = false;
          _safetyAnalysis = {
            'score': 0,
            'level': 'ERROR',
            'color': 0xFF94A3B8,
            'details': 'ANALYSIS FAILED'
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var locationData = widget.locationData;
    var touristData = widget.touristData;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          'SUBJECT DETAILS',
          style: TextStyle(
              color: _primaryText,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: _cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: _primaryText),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white10, height: 1.0),
        ),
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

            // Status Banner (if flagged or panic)
            if (locationData?['status'] == 'panic')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: _dangerColor.withOpacity(0.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: _dangerColor),
                    const SizedBox(width: 8),
                    Text('EMERGENCY ALERT ACTIVE',
                        style: TextStyle(
                            color: _dangerColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('LIVE STATUS'),
                  const SizedBox(height: 8),
                  _buildLocationCard(context),
                  const SizedBox(height: 16),
                  _buildSafetyScoreCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('IDENTITY PROFILE'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white10),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow(
                            label: 'FULL NAME',
                            value: touristData['fullName'] ?? 'N/A',
                            icon: Icons.person),
                        Divider(color: Colors.white10),
                        _buildDetailRow(
                            label: 'EMAIL ID',
                            value: touristData['email'] ?? 'N/A',
                            icon: Icons.email),
                        Divider(color: Colors.white10),
                        _buildDetailRow(
                            label: 'PHONE NO',
                            value: touristData['phoneNumber'] ?? 'N/A',
                            icon: Icons.phone),
                        Divider(color: Colors.white10),
                        _buildDetailRow(
                            label: 'AADHAAR ID',
                            value: touristData['aadharNumber'] ?? 'N/A',
                            icon: Icons.fingerprint),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('EMERGENCY CONTACTS'),
                  const SizedBox(height: 8),
                  _buildEmergencyContactsSection(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader('VERIFICATION DOCUMENTS'),
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

  Widget _buildSectionHeader(String title) {
    return Text(title,
        style: TextStyle(
            color: _accentColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5));
  }

  Widget _buildLocationCard(BuildContext context) {
    if (widget.locationData == null) return const SizedBox.shrink();
    String status = widget.locationData!['status'] ?? 'unknown';

    Color statusColor;
    String statusText;
    IconData icon;

    switch (status) {
      case 'panic':
        statusColor = _dangerColor;
        statusText = 'CRITICAL ALERT';
        icon = Icons.notification_important;
        break;
      case 'tracking':
        statusColor = _successColor;
        statusText = 'LIVE TRACKING';
        icon = Icons.gps_fixed;
        break;
      default:
        statusColor = _secondaryText;
        statusText = 'OFFLINE';
        icon = Icons.location_disabled;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusText,
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                'LAT: ${widget.locationData!['latitude']}  LONG: ${widget.locationData!['longitude']}',
                style: TextStyle(
                    color: _primaryText.withOpacity(0.7),
                    fontSize: 10,
                    fontFamily: 'monospace'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMapContainer(double lat, double lon, String status) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: _accentColor.withOpacity(0.3), width: 1)),
      ),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: LatLng(lat, lon), zoom: 15),
            markers: {
              Marker(
                markerId: const MarkerId('tourist_loc'),
                position: LatLng(lat, lon),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    _getMarkerColor(status)),
              ),
            },
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal, // Or MapType.hybrid for satellite look
          ),
          // HUD Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.3],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4)),
              child: const Text('SATELLITE LINK: ACTIVE',
                  style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  double _getMarkerColor(String status) {
    switch (status) {
      case 'panic':
        return BitmapDescriptor.hueRed;
      case 'tracking':
        return BitmapDescriptor.hueGreen;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

  Widget _buildSafetyScoreCard() {
    Color scoreColor = Color(_safetyAnalysis['color'] ?? 0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RISK ASSESSMENT',
                    style: TextStyle(
                        color: _secondaryText,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_isLoadingSafety)
                  Text('ANALYZING...',
                      style: TextStyle(
                          color: _primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold))
                else
                  Text(_safetyAnalysis['level'] ?? 'UNKNOWN',
                      style: TextStyle(
                          color: scoreColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  _safetyAnalysis['details'] ??
                      'System analyzing environmental factors...',
                  style: TextStyle(color: _secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor, width: 3),
            ),
            child: Text(
              '${_safetyAnalysis['score'] ?? 0}',
              style: TextStyle(
                  color: scoreColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      {required String label, required String value, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: _secondaryText, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: _secondaryText,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(color: _primaryText, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsSection(BuildContext context) {
    if (widget.touristData['emergencyContacts'] == null) {
      return Text('NO CONTACTS LISTED',
          style: TextStyle(color: _secondaryText, fontSize: 12));
    }

    List<dynamic> contacts = widget.touristData['emergencyContacts'] is List
        ? widget.touristData['emergencyContacts']
        : [];

    if (contacts.isEmpty) {
      return Text('NO CONTACTS LISTED',
          style: TextStyle(color: _secondaryText, fontSize: 12));
    }

    return Column(
      children: contacts.map<Widget>((contact) {
        String name = 'Contact';
        String phone = '';
        if (contact is Map) {
          name = contact['name'] ?? 'Contact';
          phone = contact['number'] ?? '';
        } else {
          phone = contact.toString();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _cardColor,
            border: Border.all(color: _dangerColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ListTile(
            dense: true,
            leading: Icon(Icons.emergency_share, color: _dangerColor),
            title: Text(name.toUpperCase(),
                style: TextStyle(
                    color: _primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            subtitle: Text(phone,
                style: TextStyle(color: _secondaryText, fontSize: 12)),
            trailing: TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Simulating Secure Call to $phone'),
                    backgroundColor: _cardColor));
              },
              icon: Icon(Icons.call, size: 16, color: _successColor),
              label: Text('CALL', style: TextStyle(color: _successColor)),
              style: TextButton.styleFrom(
                backgroundColor: _successColor.withOpacity(0.1),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDocumentsSection(BuildContext context) {
    List<dynamic> documents = widget.touristData['documents'] ?? [];

    if (documents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _cardColor,
            border: Border.all(color: Colors.white10),
            borderRadius: BorderRadius.circular(4)),
        width: double.infinity,
        child: Text('NO DOCUMENTS UPLOADED',
            style: TextStyle(color: _secondaryText, fontSize: 12),
            textAlign: TextAlign.center),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> document = Map.from(documents[index] as Map);
        bool isVerified = document['verified'] == true;
        bool isRejected = document['rejected'] == true && !isVerified;

        Color statusColor = isVerified
            ? _successColor
            : (isRejected ? _dangerColor : _warningColor);
        String statusText =
            isVerified ? 'VERIFIED' : (isRejected ? 'REJECTED' : 'PENDING');

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
              color: _cardColor,
              border: Border(left: BorderSide(color: statusColor, width: 4)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: ExpansionTile(
            collapsedIconColor: _secondaryText,
            iconColor: _accentColor,
            title: Text(
                document['name']?.toString().toUpperCase() ??
                    'DOCUMENT ${index + 1}',
                style: TextStyle(
                    color: _primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            subtitle: Text(statusText,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              _viewDocument(document['url'], context),
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('VIEW'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10,
                              foregroundColor: _primaryText),
                        ),
                        if (!isVerified)
                          ElevatedButton.icon(
                            onPressed: () =>
                                _verifyDocument(context, index, true),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('APPROVE'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _successColor.withOpacity(0.2),
                                foregroundColor: _successColor),
                          ),
                        if (!isRejected)
                          ElevatedButton.icon(
                            onPressed: () =>
                                _verifyDocument(context, index, false),
                            icon: const Icon(Icons.block, size: 16),
                            label: const Text('REJECT'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _dangerColor.withOpacity(0.2),
                                foregroundColor: _dangerColor),
                          ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _verifyDocument(
      BuildContext context, int index, bool isValid) async {
    // (Existing logic maintained, just wrapped in try-catch)
    try {
      List<dynamic> documents =
          List.from(widget.touristData['documents'] ?? []);

      if (index >= 0 && index < documents.length) {
        Map<String, dynamic> doc = Map.from(documents[index] as Map);
        doc['verified'] = isValid;
        doc['rejected'] = !isValid;
        doc['verifiedAt'] = Timestamp.now();
        documents[index] = doc;

        final uid = widget.touristData['uid'];
        if (uid != null) {
          final userRef =
              FirebaseFirestore.instance.collection('users').doc(uid);

          await userRef.update({'documents': documents});
          await userRef.collection('notifications').add({
            'title': isValid ? 'Document Verified' : 'Document Rejected',
            'message': isValid
                ? 'Your document has been approved by authority.'
                : 'Your document was rejected. Please review.',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': isValid ? 'success' : 'alert',
          });

          if (!isValid) {
            await userRef.update({'isFlagged': true});
          }

          if (mounted) {
            // Refresh parent data? Actually we just need to update UI locally or wait for stream if we had one.
            // We are using passed data, so we should update local state to reflect change immediately if possible,
            // or just show snackbar. Since we are in a DetailScreen with static passed data, we can't easily auto-refresh
            // without listening to a stream of the user.
            // Ideally we should convert this screen to listen to the user stream, but for now:
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('STATUS UPDATED'),
                backgroundColor: isValid ? _successColor : _dangerColor));
            Navigator.pop(
                context); // Close to force refresh on list (simplest way)
          }
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('ERROR: $e'), backgroundColor: _dangerColor));
    }
  }

  void _viewDocument(String url, BuildContext context) {
    if (url.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (ctx) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  iconTheme: const IconThemeData(color: Colors.white)),
              body: Center(child: Image.network(url)),
            )));
  }
}
