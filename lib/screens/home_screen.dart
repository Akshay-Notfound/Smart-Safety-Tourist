import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Add this for SocketException
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'digital_id_screen.dart';
// !! NAVIN FILES IMPORT KELYA !!
import 'itinerary_screen.dart';
import 'emergency_contacts_screen.dart';
import 'document_upload_screen.dart';
import 'aadhar_detail_screen.dart';
import 'edit_profile_screen.dart'; // Add this import

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
  int _safetyScore = 50; // Initialize with a neutral score instead of 85

  // Location aani Weather sathi variables
  bool _isSharingLocation = false;
  Map<String, dynamic>? _weatherData;
  final Location _locationService = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  final String _weatherApiKey = "ea2ffad27dfe39aae155a62240a965b7";

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _stopLocationUpdates();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    try {
      await _fetchUserData();
      await _refreshSafetyStatus(showSnackbar: false);
    } catch (e) {
      print('Error initializing screen: $e');
      // Even if there's an error, we should stop showing the loading indicator
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

  Future<bool> _fetchWeatherData() async {
    try {
      bool serviceEnabled = await _locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationService.requestService();
        if (!serviceEnabled) return false;
      }
      PermissionStatus permissionGranted =
      await _locationService.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _locationService.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return false;
      }

      // Add timeout to prevent hanging
      final currentLocation = await _locationService.getLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Location request timeout', const Duration(seconds: 10));
        },
      );
      final lat = currentLocation.latitude;
      final lon = currentLocation.longitude;
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_weatherApiKey&units=metric';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout', const Duration(seconds: 10));
        },
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _weatherData = json.decode(response.body);
        });
        return true;
      } else {
        if (mounted) {
          String errorMessage = 'Failed to load weather data.';
          try {
            final errorBody = json.decode(response.body);
            errorMessage = errorBody['message'] ?? 'Weather API error occurred.';
          } catch (e) {
            // If we can't parse the error body, use the status code
            errorMessage = 'Weather API error: ${response.statusCode}';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ));
        }
        return false;
      }
    } on SocketException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('No internet connection. Please check your network.'),
          backgroundColor: Colors.red,
        ));
      }
      return false;
    } on TimeoutException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Request timeout. Please try again.'),
          backgroundColor: Colors.red,
        ));
      }
      return false;
    } catch (e) {
      print('Weather fetch error: $e');
      if (mounted) {
        // Check if we have internet connectivity
        try {
          final result = await InternetAddress.lookup('google.com');
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Weather service temporarily unavailable. Please try again.'),
              backgroundColor: Colors.orange,
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('No internet connection. Please check your network.'),
              backgroundColor: Colors.red,
            ));
          }
        } on SocketException catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('No internet connection. Please check your network.'),
            backgroundColor: Colors.red,
          ));
        }
      }
      return false;
    }
  }

  int _calculateSafetyScore(Map<String, dynamic>? weather) {
    if (weather == null) return 50;
    int score = 100;
    String weatherCondition = weather['weather'][0]['main'];
    double windSpeed = weather['wind']['speed'] * 3.6;

    if (weatherCondition == 'Thunderstorm' || weatherCondition == 'Tornado') {
      score -= 60;
    } else if (weatherCondition == 'Rain' || weatherCondition == 'Snow') {
      score -= 30;
    } else if (weatherCondition == 'Mist' || weatherCondition == 'Fog') {
      score -= 20;
    }

    if (windSpeed > 50) {
      score -= 40;
    } else if (windSpeed > 30) {
      score -= 20;
    }

    return score.clamp(0, 100);
  }

  Future<void> _refreshSafetyStatus({bool showSnackbar = true}) async {
    if (mounted && showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Fetching live weather to update status...'),
        duration: Duration(seconds: 2),
      ));
    }
    bool success = await _fetchWeatherData();
    if (success && mounted) {
      setState(() {
        _safetyScore = _calculateSafetyScore(_weatherData);
      });
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Safety Status Updated based on live weather!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ));
      }
    }
  }

  void _showWeatherInfo() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    await _fetchWeatherData();
    if (mounted) Navigator.pop(context);

    if (mounted && _weatherData != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => WeatherInfoSheet(weatherData: _weatherData!),
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

      _locationSubscription =
          _locationService.onLocationChanged.listen((LocationData currentLocation) {
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
                print('Location updated for user ${user!.uid}: ${currentLocation.latitude}, ${currentLocation.longitude}');
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
      FirebaseFirestore.instance.collection('live_locations').doc(user!.uid).delete();
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
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Panic Button Pressed! Alerting authorities...'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String safetyStatusText =
    _safetyScore > 50 ? "Safe Zone" : "High-Risk Area";
    Color safetyStatusColor =
    _safetyScore > 50 ? Colors.green.shade800 : Colors.red.shade800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home - Smart Safety'),
        backgroundColor: Colors.deepPurple.shade400,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              _stopLocationUpdates(); // Logout kartana location updates thambva
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
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
                    _weatherData == null 
                      ? 'Loading safety score...' 
                      : '$_safetyScore/100',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(_safetyScore),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _weatherData == null 
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
            _buildInfoCard(
              icon: Icons.touch_app_outlined,
              title: 'Quick Actions',
              child: Column(
                children: [
                  _buildActionButton(
                      context, Icons.person, 'Edit Profile'),
                  const Divider(),
                  _buildActionButton(
                      context, Icons.badge_outlined, 'View Digital ID'),
                  const Divider(),
                  _buildActionButton(
                      context, Icons.map_outlined, 'Manage Itinerary'),
                  const Divider(),
                  _buildActionButton(context,
                      Icons.contact_phone_outlined, 'Emergency Contacts'),
                  const Divider(),
                  _buildActionButton(context,
                      Icons.upload_file, 'Upload Documents'),
                  const Divider(),
                  _buildActionButton(context,
                      Icons.badge, 'View Aadhaar Details'),
                ],
              ),
            ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onPanicPressed,
        label: const Text('PANIC'),
        icon: const Icon(Icons.warning_amber_rounded),
        backgroundColor: Colors.red.shade700,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // !! CODE UPDATE KELA !!
  Widget _buildActionButton(BuildContext context, IconData icon, String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.deepPurple.shade400),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Digital ID sathi logic
        if (title == 'View Digital ID' && userData != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DigitalIdScreen(userData: userData!),
            ),
          );
        }
        // Itinerary sathi navin logic
        else if (title == 'Manage Itinerary') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ItineraryScreen()),
          );
        }
        // Emergency Contacts sathi navin logic
        else if (title == 'Emergency Contacts') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EmergencyContactsScreen()),
          );
        }
        // Document Upload logic
        else if (title == 'Upload Documents') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DocumentUploadScreen()),
          );
        }
        // Aadhaar Details logic
        else if (title == 'View Aadhaar Details' && user != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AadharDetailScreen(userId: user!.uid)),
          );
        }
        // Edit Profile logic
        else if (title == 'Edit Profile' && userData != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EditProfileScreen(userData: userData!)),
          ).then((value) {
            if (value == true) {
              // Refresh user data after successful edit
              _fetchUserData();
            }
          });
        }
      },
    );
  }

  Color _getScoreColor(int score) {
    if (score > 75) return Colors.green.shade700;
    if (score > 40) return Colors.orange.shade700;
    return Colors.red.shade700;
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

class WeatherInfoSheet extends StatelessWidget {
  final Map<String, dynamic> weatherData;
  const WeatherInfoSheet({super.key, required this.weatherData});

  IconData _getWeatherIcon(String condition) {
    switch (condition) {
      case 'Thunderstorm':
        return Icons.thunderstorm;
      case 'Drizzle':
        return Icons.grain;
      case 'Rain':
        return Icons.water_drop;
      case 'Snow':
        return Icons.ac_unit;
      case 'Clear':
        return Icons.wb_sunny;
      case 'Clouds':
        return Icons.cloud;
      default:
        return Icons.wb_cloudy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final condition = weatherData['weather'][0]['main'];
    final temp = weatherData['main']['temp'].round();
    final windSpeed = (weatherData['wind']['speed'] * 3.6).toStringAsFixed(1);
    final humidity = weatherData['main']['humidity'];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade300,
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            weatherData['name'] ?? 'Current Location',
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getWeatherIcon(condition), size: 60, color: Colors.white),
              const SizedBox(width: 20),
              Text(
                '$temp°C',
                style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w200,
                    color: Colors.white),
              ),
            ],
          ),
          Text(
            condition,
            style: const TextStyle(
                fontSize: 20, color: Colors.white70, letterSpacing: 2),
          ),
          const Divider(color: Colors.white54, height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail(Icons.air, 'Wind', '$windSpeed km/h'),
              _buildWeatherDetail(
                  Icons.water_drop_outlined, 'Humidity', '$humidity%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(fontSize: 14, color: Colors.white70)),
      ],
    );
  }
}

