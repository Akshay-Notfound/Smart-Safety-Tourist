import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/theme_provider.dart';
import 'services/weather_service.dart';

import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/authority_dashboard_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => WeatherService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Tourist Safety',
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const AuthWrapper(),
    );
  }
}

// Ha widget user cha login status aani role check karto
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Jar user login nasel, tar WelcomeScreen dakhav
        if (!snapshot.hasData) {
          return const WelcomeScreen();
        }

        // Jar user login ahe, tar tyacha role check kar
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get()
              .timeout(const Duration(seconds: 10)),
          builder: (context, userDocSnapshot) {
            if (userDocSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            if (!userDocSnapshot.hasData || !userDocSnapshot.data!.exists) {
              // Jar kahi karanane user cha data milala nahi, tar logout karu
              WidgetsBinding.instance.addPostFrameCallback((_) {
                FirebaseAuth.instance.signOut();
              });
              return const WelcomeScreen();
            }

            final userData =
                userDocSnapshot.data!.data() as Map<String, dynamic>;
            final role = userData['role'];

            // Role nusar screen dakhav
            if (role == 'authority') {
              return const AuthorityDashboardScreen();
            } else {
              // Jar role 'tourist' asel kiwa kahich nasel, tar HomeScreen dakhav
              return const HomeScreen();
            }
          },
        );
      },
    );
  }
}
