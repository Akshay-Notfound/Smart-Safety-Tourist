import 'dart:async';
import 'dart:io'; // Add this for SocketException
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourist_app/services/weather_service.dart';
import 'digital_id_screen.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  // User aani UI sathi variables
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  // int _safetyScore = 50; // Removed unused variable

  // Location sathi variables
  bool _isSharingLocation = false;
  final Location _locationService = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _checkForUpdates();
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
    _stopLocationUpdates();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    try {
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
        // We still want to proceed even if we can't fetch user data immediately
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

      // Add timeout to prevent hanging
      final currentLocation = await _locationService.getLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Location request timeout', const Duration(seconds: 10));
        },
      );

      // Get weather service and fetch data
      final weatherService =
          Provider.of<WeatherService>(context, listen: false);
      await weatherService.fetchWeatherData(
          currentLocation.latitude!, currentLocation.longitude!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Weather data updated successfully!'),
          backgroundColor: Colors.green,
        ));
      }
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              const Text('No internet connection. Please check your network.'),
          backgroundColor: Colors.red,
        ));
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Request timeout. Please try again.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print('Weather fetch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              const Text('Failed to fetch weather data. Please try again.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _refreshSafetyStatus({bool showSnackbar = true}) async {
    if (mounted && showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Fetching live weather to update status...'),
        duration: Duration(seconds: 2),
      ));
    }
    await _fetchWeatherData();
    // Safety score is now calculated by the WeatherService
    if (mounted && showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Safety Status Updated based on live weather!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ));
    }
  }

  void _showWeatherInfo() async {
    // Refresh weather data
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
            // Add debug print to confirm location update
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
            backgroundColor: Colors.green));
      }
    } else {
      _stopLocationUpdates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Live location sharing is OFF.'),
            backgroundColor: Colors.grey));
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

      // Show confirmation dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Panic Alert Sent!'),
              content: const Text(
                  'Authorities have been notified. Help is on the way.'),
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
      appBar: AppBar(
        title: const Text('Home - Smart Safety (Updated)'),
        backgroundColor: Colors.deepPurple.shade400,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              _stopLocationUpdates();
              LogoutService.showLogoutDialog(context);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade400,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      if (userData != null) {
                        _navigateToScreen(
                            EditProfileScreen(userData: userData!));
                      }
                    },
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: userData?['profileImage'] != null &&
                              userData!['profileImage'].toString().isNotEmpty
                          ? NetworkImage(userData!['profileImage'])
                          : null,
                      child: userData?['profileImage'] != null &&
                              userData!['profileImage'].toString().isNotEmpty
                          ? null
                          : Text(
                              userData?['fullName']?.toString().isNotEmpty ==
                                      true
                                  ? userData!['fullName'][0].toUpperCase()
                                  : 'T',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.deepPurple.shade400,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userData?['fullName'] ?? 'Tourist',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userData?['email'] ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                if (userData != null) {
                  _navigateToScreen(EditProfileScreen(userData: userData!));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('View Digital ID'),
              onTap: () {
                Navigator.pop(context);
                if (userData != null) {
                  _navigateToScreen(DigitalIdScreen(userData: userData!));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('Manage Itinerary'),
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen(ItineraryScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_phone_outlined),
              title: const Text('Emergency Contacts'),
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen(EmergencyContactsScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload Documents'),
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen(DocumentUploadScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('View Aadhaar Details'),
              onTap: () {
                Navigator.pop(context);
                if (user != null) {
                  _navigateToScreen(AadharDetailScreen(userId: user!.uid));
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Community Chat'),
              onTap: () {
                Navigator.pop(context);
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
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Safety Status'),
              onTap: () {
                Navigator.pop(context);
                _refreshSafetyStatus();
              },
            ),
            ListTile(
              leading: const Icon(Icons.track_changes_outlined),
              title: const Text('Live Tracking'),
              trailing: Switch(
                value: _isSharingLocation,
                onChanged: (value) {
                  Navigator.pop(context);
                  _toggleLocationSharing(value);
                },
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleLocationSharing(!_isSharingLocation);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                _stopLocationUpdates();
                LogoutService.showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome,',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                  Text(
                    userData?['fullName'] ?? 'Tourist',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard(
                    icon: Icons.shield_outlined,
                    title: 'Your Safety Status',
                    actionButton: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.info_outline,
                              color: Colors.blue.shade400),
                          onPressed: _showWeatherInfo,
                          tooltip: 'Check Live Weather',
                        ),
                        IconButton(
                          icon:
                              Icon(Icons.refresh, color: Colors.grey.shade600),
                          onPressed: _refreshSafetyStatus,
                          tooltip: 'Refresh Status',
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          weatherService.isLoading
                              ? 'Loading...'
                              : '${safetyScore}/100',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(safetyScore),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          weatherService.isLoading
                              ? 'Fetching weather data...'
                              : 'Current Status: $safetyStatusText',
                          style: TextStyle(
                            fontSize: 16,
                            color: safetyStatusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.track_changes_outlined,
                    title: 'Live Tracking',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Share My Location in Real-Time'),
                      subtitle: const Text(
                          'Allows family & authorities to track you.'),
                      trailing: Switch(
                        value: _isSharingLocation,
                        onChanged: _toggleLocationSharing,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Column(
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
            label: const Text('AI Assistant'),
            icon: const Icon(Icons.smart_toy),
            backgroundColor: Colors.deepPurple,
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'panic_btn',
            onPressed: _onPanicPressed,
            label: const Text('PANIC'),
            icon: const Icon(Icons.warning_amber_rounded),
            backgroundColor: Colors.red.shade700,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
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

  Widget _buildInfoCard(
      {required IconData icon,
      required String title,
      required Widget child,
      Widget? actionButton}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                if (actionButton != null) actionButton,
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
