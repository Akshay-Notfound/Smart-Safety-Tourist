import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vibration/vibration.dart';
import 'qr_scanner_screen.dart';
import 'tourist_detail_screen.dart';
import 'aadhar_detail_screen.dart';
import 'authority_settings_screen.dart';
import 'chat_screen.dart';
import 'edit_profile_screen.dart';
import 'package:smart_tourist_app/services/logout_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class AuthorityDashboardScreen extends StatefulWidget {
  const AuthorityDashboardScreen({super.key});

  @override
  State<AuthorityDashboardScreen> createState() =>
      _AuthorityDashboardScreenState();
}

class _AuthorityDashboardScreenState extends State<AuthorityDashboardScreen>
    with TickerProviderStateMixin {
  StreamSubscription? _panicSubscription;
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Theme Constants
  final Color _bgDark = const Color(0xFF0F172A); // Slate 900
  final Color _cardDark = const Color(0xFF1E293B); // Slate 800
  final Color _accentGold = const Color(0xFFF59E0B); // Amber 500
  final Color _accentSky = const Color(0xFF38BDF8); // Sky 400
  final Color _textLight = const Color(0xFFF8FAFC); // Slate 50
  final Color _textDim = const Color(0xFF94A3B8); // Slate 400

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _listenForPanicAlerts();
  }

  void _listenForPanicAlerts() {
    _panicSubscription = FirebaseFirestore.instance
        .collection('live_locations')
        .where('status', isEqualTo: 'panic')
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        bool? hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate(duration: 1000, amplitude: 128);
        }
      }
    });
  }

  @override
  void dispose() {
    _panicSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgDark,
      appBar: AppBar(
        title: Text('COMMAND CENTER',
            style: TextStyle(
                color: _textLight,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 16)),
        backgroundColor: _cardDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.grid_view_rounded, color: _accentSky),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.power_settings_new_rounded,
                color: Colors.red.shade400),
            onPressed: () {
              LogoutService.showLogoutDialog(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _accentGold,
          indicatorWeight: 3,
          labelColor: _accentGold,
          unselectedLabelColor: _textDim,
          tabs: const [
            Tab(
              icon: Icon(Icons.list_alt_rounded),
              child: Text('LIVE FEED',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Tab(
              icon: Icon(Icons.map_rounded),
              child: Text('GEO MAP',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TouristListView(),
          LiveMapView(),
        ],
      ),
      floatingActionButton: _buildConditionalFAB(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _bgDark,
      child: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              String userName = 'Officer';
              String email = 'ID: Unknown';
              String? profileImage;
              Map<String, dynamic> userData = {};

              if (snapshot.hasData && snapshot.data!.exists) {
                userData = snapshot.data!.data() as Map<String, dynamic>;
                userName = userData['fullName'] ?? 'Officer';
                email = userData['email'] ?? 'ID: Unknown';
                profileImage = userData['profileImage'];
              }

              return Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                decoration: BoxDecoration(
                  color: _cardDark,
                  border:
                      Border(bottom: BorderSide(color: _accentGold, width: 2)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _bgDark,
                      backgroundImage:
                          profileImage != null && profileImage.isNotEmpty
                              ? NetworkImage(profileImage)
                              : null,
                      child: profileImage != null && profileImage.isNotEmpty
                          ? null
                          : Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : 'A',
                              style: TextStyle(
                                  fontSize: 24,
                                  color: _accentGold,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName,
                              style: TextStyle(
                                  color: _textLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(email,
                              style: TextStyle(color: _textDim, fontSize: 12)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: _accentGold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    Border.all(color: _accentGold, width: 0.5)),
                            child: Text('AUTHORITY',
                                style: TextStyle(
                                    color: _accentGold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildDrawerItem(Icons.qr_code_scanner, 'Scan ID', () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => const QRScannerScreen()));
                }),
                _buildDrawerItem(Icons.chat_bubble_outline, 'Comms Channel',
                    () async {
                  Navigator.pop(context);
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final doc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .get();
                    if (doc.exists) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (c) => ChatScreen(
                                  userData:
                                      doc.data() as Map<String, dynamic>)));
                    }
                  }
                }),
                _buildDrawerItem(Icons.person_outline, 'Officer Profile',
                    () async {
                  Navigator.pop(context);
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final doc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .get();
                    if (doc.exists) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (c) => EditProfileScreen(
                                  userData:
                                      doc.data() as Map<String, dynamic>)));
                    }
                  }
                }),
                _buildDrawerItem(Icons.settings_outlined, 'System Settings',
                    () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => const AuthoritySettingsScreen()));
                }),
                const Divider(color: Colors.white10),
                _buildDrawerItem(Icons.logout, 'Log Out', () {
                  Navigator.pop(context);
                  LogoutService.showLogoutDialog(context);
                }, isDestructive: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading:
          Icon(icon, color: isDestructive ? Colors.red.shade400 : _accentSky),
      title: Text(title,
          style: TextStyle(
              color: isDestructive ? Colors.red.shade400 : _textLight,
              fontWeight: FontWeight.w500)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Widget _buildConditionalFAB() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        return _tabController.index == 0
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => const QRScannerScreen()));
                },
                label: const Text('SCAN ID',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black)),
                icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
                backgroundColor: _accentGold,
              )
            : const SizedBox.shrink();
      },
    );
  }
}

class TouristListView extends StatelessWidget {
  const TouristListView({super.key});

  @override
  Widget build(BuildContext context) {
    // Theme references (hardcoded for stateless consistency within the file style)
    final Color bgDark = const Color(0xFF0F172A);
    final Color cardDark = const Color(0xFF1E293B);
    final Color accentGold = const Color(0xFFF59E0B);
    final Color accentSky = const Color(0xFF38BDF8);
    final Color textLight = const Color(0xFFF8FAFC);
    final Color textDim = const Color(0xFF94A3B8);

    return Container(
      color: bgDark,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'tourist')
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accentGold));
          }
          if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
            return Center(
                child: Text('No active tourists.',
                    style: TextStyle(color: textDim)));
          }

          final tourists = userSnapshot.data!.docs;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('live_locations')
                .snapshots(),
            builder: (context, locationSnapshot) {
              Map<String, DocumentSnapshot> liveLocations = {};
              if (locationSnapshot.hasData) {
                for (var doc in locationSnapshot.data!.docs) {
                  liveLocations[doc.id] = doc;
                }
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tourists.length,
                itemBuilder: (context, index) {
                  var touristData =
                      tourists[index].data() as Map<String, dynamic>;
                  var touristId = tourists[index].id;
                  touristData['uid'] = touristId;

                  var locationDoc = liveLocations[touristId];
                  var locationData =
                      locationDoc?.data() as Map<String, dynamic>?;

                  // Status Logic
                  String statusText = 'INACTIVE';
                  Color statusColor = textDim;
                  IconData statusIcon = Icons.circle_outlined;

                  if (locationData != null) {
                    var status = locationData['status'];
                    if (status == 'panic') {
                      statusText = 'PANIC ALERT';
                      statusColor = Colors.red.shade500;
                      statusIcon = Icons.warning_rounded;
                    } else if (status == 'tracking') {
                      // Check stale
                      var timestamp =
                          (locationData['timestamp'] as Timestamp?)?.toDate();
                      if (timestamp != null &&
                          DateTime.now().difference(timestamp).inMinutes > 15) {
                        statusText = 'STALE SIGNAL';
                        statusColor = Colors.orange.shade400;
                        statusIcon = Icons.signal_wifi_bad;
                      } else {
                        statusText = 'LIVE TRACKING';
                        statusColor = Colors.green.shade400;
                        statusIcon = Icons.gps_fixed;
                      }
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: cardDark,
                        border: Border(
                            left: BorderSide(color: statusColor, width: 4)),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ]),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: bgDark,
                        backgroundImage: touristData['profileImage'] != null &&
                                touristData['profileImage']
                                    .toString()
                                    .isNotEmpty
                            ? NetworkImage(touristData['profileImage'])
                            : null,
                        child: touristData['profileImage'] == null ||
                                touristData['profileImage'].toString().isEmpty
                            ? Text(touristData['fullName']?[0] ?? 'T',
                                style: TextStyle(color: accentSky))
                            : null,
                      ),
                      title: Text(
                        touristData['fullName'] ?? 'Unknown',
                        style: TextStyle(
                            color: textLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(statusIcon, color: statusColor, size: 14),
                              const SizedBox(width: 6),
                              Text(statusText,
                                  style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (touristData['phoneNumber'] != null)
                            Text('Phone: ${touristData['phoneNumber']}',
                                style: TextStyle(color: textDim, fontSize: 12)),
                        ],
                      ),
                      trailing: Icon(Icons.chevron_right, color: textDim),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => TouristDetailScreen(
                                    touristData: touristData,
                                    locationData: locationData)));
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class LiveMapView extends StatelessWidget {
  const LiveMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('live_locations').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ... (Logic for markers same as before) ...
        // Re-implementing logic compactly
        Set<Marker> markers = <Marker>{};
        List<Map<String, dynamic>> locationList = [];

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            locationList.add({'id': doc.id, 'data': data});

            if (data['latitude'] != null && data['longitude'] != null) {
              final lat = data['latitude'];
              final lon = data['longitude'];
              final status = data['status'];

              BitmapDescriptor icon = BitmapDescriptor.defaultMarker;
              if (status == 'panic') {
                icon = BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed);
              } else {
                icon = BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen);
              }

              markers.add(Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(lat, lon),
                icon: icon,
                infoWindow: InfoWindow(
                    title: data['touristName'] ?? 'Tourist', snippet: status),
              ));
            }
          }
        }

        if (markers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 60, color: Colors.white24),
                const SizedBox(height: 16),
                const Text('NO ACTIVE SIGNALS',
                    style: TextStyle(
                        color: Colors.white54,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        return GoogleMap(
          initialCameraPosition:
              CameraPosition(target: markers.first.position, zoom: 12),
          markers: markers,
          mapType: MapType.hybrid, // Hybrid looks more "Command Center"
          myLocationEnabled: true,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
        );
      },
    );
  }
}
