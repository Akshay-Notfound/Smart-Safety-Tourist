import 'dart:async';
import 'dart:io'; // Add this for SocketException
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourist_app/services/weather_service.dart';
import 'digital_id_screen.dart';
import 'package:smart_tourist_app/screens/notification_screen.dart';
// !! NAVIN FILES IMPORT KELYA !!
// !! NAVIN FILES IMPORT KELYA !!
import 'package:smart_tourist_app/services/version_check_service.dart';
import 'package:smart_tourist_app/widgets/update_dialog.dart';
import 'itinerary_screen.dart';
import 'emergency_contacts_screen.dart';
import 'document_upload_screen.dart';
import 'aadhar_detail_screen.dart';
import 'edit_profile_screen.dart';
import 'weather_info_sheet.dart';
import 'settings_screen.dart';
import 'smart_assistant_screen.dart';
import 'chat_screen.dart';
import 'package:smart_tourist_app/services/logout_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // User aani UI sathi variables
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool _isLoading = true;

  // Location sathi variables
  bool _isSharingLocation = false;
  final Location _locationService = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation Controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _checkForUpdates();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  Future<void> _checkForUpdates() async {
    final versionService = VersionCheckService();
    final updateInfo = await versionService.checkVersion();

    if (updateInfo != null && updateInfo['updateAvailable'] == true) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => UpdateDialog(
            latestVersion: updateInfo['latestVersion'],
            apkUrl: updateInfo['apkUrl'],
            changes: updateInfo['changes'],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stopLocationUpdates();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    try {
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
      await _fetchUserData();
      // Don't block the UI initialization on weather data
      _refreshSafetyStatus(showSnackbar: false);
    } catch (e) {
      print('Error initializing screen: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get()
            .timeout(const Duration(seconds: 10));
        if (mounted) {
          setState(() {
            userData = userDoc.data() as Map<String, dynamic>?;
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
        if (mounted) {
          setState(() {
            userData = {};
          });
        }
      }
    }
  }

  Future<void> _fetchWeatherData() async {
    try {
      bool serviceEnabled = await _locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationService.requestService();
        if (!serviceEnabled) return;
      }
      PermissionStatus permissionGranted =
          await _locationService.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _locationService.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      final currentLocation = await _locationService.getLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Location request timeout', const Duration(seconds: 10));
        },
      );

      final weatherService =
          Provider.of<WeatherService>(context, listen: false);
      await weatherService.fetchWeatherData(
          currentLocation.latitude!, currentLocation.longitude!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Weather data updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No internet connection. Please check your network.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Request timeout. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      print('Weather fetch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to fetch weather data. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _refreshSafetyStatus({bool showSnackbar = true}) async {
    if (mounted && showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Fetching live weather to update status...'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    }
    await _fetchWeatherData();
    if (mounted && showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Safety Status Updated based on live weather!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showWeatherInfo() async {
    await _fetchWeatherData();
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const WeatherInfoSheet(),
      );
    }
  }

  void _toggleLocationSharing(bool isSharing) async {
    if (mounted) setState(() => _isSharingLocation = isSharing);

    if (_isSharingLocation) {
      bool serviceEnabled = await _locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationService.requestService();
        if (!serviceEnabled) {
          if (mounted) setState(() => _isSharingLocation = false);
          return;
        }
      }
      PermissionStatus permissionGranted =
          await _locationService.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _locationService.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          if (mounted) setState(() => _isSharingLocation = false);
          return;
        }
      }

      _locationSubscription = _locationService.onLocationChanged
          .listen((LocationData currentLocation) {
        if (user != null) {
          FirebaseFirestore.instance
              .collection('live_locations')
              .doc(user!.uid)
              .set({
            'latitude': currentLocation.latitude,
            'longitude': currentLocation.longitude,
            'timestamp': FieldValue.serverTimestamp(),
            'touristName': userData?['fullName'] ?? 'Unknown Tourist',
            'status': 'tracking'
          }).then((_) {
            print(
                'Location updated for user ${user!.uid}: ${currentLocation.latitude}, ${currentLocation.longitude}');
          }).catchError((error) {
            print('Error updating location: $error');
          });
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Live location sharing is ON.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating));
      }
    } else {
      _stopLocationUpdates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Live location sharing is OFF.'),
            backgroundColor: Colors.grey,
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  void _stopLocationUpdates() {
    _locationSubscription?.cancel();
    if (user != null) {
      FirebaseFirestore.instance
          .collection('live_locations')
          .doc(user!.uid)
          .delete();
    }
  }

  void _onPanicPressed() {
    if (!_isSharingLocation) {
      _toggleLocationSharing(true);
    }
    if (user != null) {
      FirebaseFirestore.instance
          .collection('live_locations')
          .doc(user!.uid)
          .update({'status': 'panic'});

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Panic Alert Sent!',
                  style: TextStyle(color: Colors.red)),
              content: const Text(
                  'Authorities have been notified. Help is on the way.'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherService = Provider.of<WeatherService>(context);
    final safetyScore = weatherService.calculateSafetyScore();
    final safetyStatusText = weatherService.getSafetyStatusText();
    final safetyStatusColor =
        safetyScore > 50 ? Colors.green.shade800 : Colors.red.shade800;

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Home - Smart Safety',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: user != null
                ? FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('notifications')
                    .where('isRead', isEqualTo: false)
                    .snapshots()
                : null,
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.length;
              }
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificationScreen()),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              _stopLocationUpdates();
              LogoutService.showLogoutDialog(context);
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurpleAccent.shade200
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWarningBanner(),
                          const SizedBox(height: 10),
                          Text(
                            'Welcome,',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            userData?['fullName'] ?? 'Tourist',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildModernCard(
                            icon: Icons.shield_outlined,
                            title: 'Your Safety Status',
                            subtitle: 'Current Status: $safetyStatusText',
                            child: Column(
                              children: [
                                Text(
                                  weatherService.isLoading
                                      ? '...'
                                      : '${safetyScore}/100',
                                  style: TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    color: _getScoreColor(safetyScore),
                                  ),
                                ),
                                Text(
                                  weatherService.isLoading
                                      ? 'Checking...'
                                      : safetyStatusText,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: safetyStatusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              IconButton(
                                icon: Icon(Icons.info_outline,
                                    color: Colors.blue.shade600),
                                onPressed: _showWeatherInfo,
                                tooltip: 'Check Live Weather',
                              ),
                              IconButton(
                                icon: Icon(Icons.refresh,
                                    color: Colors.grey.shade600),
                                onPressed: _refreshSafetyStatus,
                                tooltip: 'Refresh Status',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildModernCard(
                            icon: Icons.track_changes_outlined,
                            title: 'Live Tracking',
                            subtitle:
                                'Share My Location in Real-Time\nAllows family & authorities to track you.',
                            child: Container(),
                            trailing: Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: _isSharingLocation,
                                onChanged: _toggleLocationSharing,
                                activeColor: Colors.deepPurple,
                              ),
                            ),
                          ),
                          const SizedBox(height: 100), // Space for FABs
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              heroTag: 'ai_assistant',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SmartAssistantScreen()),
                );
              },
              label: const Text('AI Assistant',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.smart_toy),
              backgroundColor: Colors.deepPurple.shade700,
              elevation: 4,
            ),
            const SizedBox(height: 16),
            FloatingActionButton.extended(
              heroTag: 'panic_btn',
              onPressed: _onPanicPressed,
              label: const Text('PANIC',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              icon: const Icon(Icons.warning_amber_rounded),
              backgroundColor: Colors.red.shade700,
              elevation: 8,
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade800,
                    Colors.deepPurpleAccent.shade200
                  ],
                ),
              ),
              accountName: Text(
                userData?['fullName'] ?? 'Tourist',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                userData?['email'] ?? '',
                style: const TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  if (userData != null) {
                    _navigateToScreen(EditProfileScreen(userData: userData!));
                  }
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: userData?['profileImage'] != null &&
                          userData!['profileImage'].toString().isNotEmpty
                      ? NetworkImage(userData!['profileImage'])
                      : null,
                  child: userData?['profileImage'] != null &&
                          userData!['profileImage'].toString().isNotEmpty
                      ? null
                      : Text(
                          userData?['fullName']?.toString().isNotEmpty == true
                              ? userData!['fullName'][0].toUpperCase()
                              : 'T',
                          style: TextStyle(
                            fontSize: 32,
                            color: Colors.deepPurple.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            _buildDrawerItem(Icons.person, 'Edit Profile', () {
              if (userData != null) {
                _navigateToScreen(EditProfileScreen(userData: userData!));
              }
            }),
            _buildDrawerItem(Icons.badge_outlined, 'View Digital ID', () {
              if (userData != null) {
                _navigateToScreen(DigitalIdScreen(userData: userData!));
              }
            }),
            _buildDrawerItem(Icons.map_outlined, 'Manage Itinerary', () {
              _navigateToScreen(ItineraryScreen());
            }),
            _buildDrawerItem(Icons.contact_phone_outlined, 'Emergency Contacts',
                () {
              _navigateToScreen(EmergencyContactsScreen());
            }),
            _buildDrawerItem(Icons.upload_file, 'Upload Documents', () {
              _navigateToScreen(DocumentUploadScreen());
            }),
            _buildDrawerItem(Icons.badge, 'View Aadhaar Details', () {
              if (user != null) {
                _navigateToScreen(AadharDetailScreen(userId: user!.uid));
              }
            }),
            const Divider(),
            _buildDrawerItem(Icons.chat_bubble_outline, 'Community Chat', () {
              if (userData != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(userData: userData!),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please wait for user data to load')),
                );
              }
            }),
            _buildDrawerItem(Icons.shield_outlined, 'Safety Status', () {
              _refreshSafetyStatus();
            }),
            ListTile(
              leading: Icon(Icons.track_changes_outlined,
                  color: Colors.deepPurple.shade700),
              title: const Text('Live Tracking'),
              trailing: Switch(
                value: _isSharingLocation,
                onChanged: (value) {
                  Navigator.pop(context);
                  _toggleLocationSharing(value);
                },
                activeColor: Colors.deepPurple,
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleLocationSharing(!_isSharingLocation);
              },
            ),
            const Divider(),
            _buildDrawerItem(Icons.settings, 'Settings', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            }),
            _buildDrawerItem(Icons.logout, 'Logout', () async {
              _stopLocationUpdates();
              LogoutService.showLogoutDialog(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple.shade700),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _buildModernCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
    List<Widget>? actions,
    Widget? trailing,
  }) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.deepPurple.shade700, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (actions != null) Row(children: actions),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            child,
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    if (userData?['isFlagged'] == true ||
        userData?['documentStatus'] == 'rejected') {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50.withOpacity(0.9),
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Action Required',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your account is flagged. Please contact support.',
                    style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }

  Color _getScoreColor(int score) {
    if (score > 75) return Colors.green.shade700;
    if (score > 40) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  void _navigateToScreen(Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    if (result == true) {
      _fetchUserData();
    }
  }
}
