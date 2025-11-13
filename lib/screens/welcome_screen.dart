import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'authority_login_screen.dart';
import 'authority_register_screen.dart'; // Navin file import keli

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Tourist Safety'),
        backgroundColor: Colors.deepPurple.shade300,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Welcome!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Select your role to get started',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              // Tourist Login Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    // !! ERROR THIK KELA !! - 'const' kadhun takla
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(250, 50),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Login as Tourist'),
              ),
              const SizedBox(height: 20),
              // Tourist Register Button
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    // !! ERROR THIK KELA !! - 'const' kadhun takla
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(250, 50),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Register as Tourist'),
              ),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),
              // Authority sathi Register button
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    // !! ERROR THIK KELA !! - 'const' kadhun takla
                    MaterialPageRoute(
                        builder: (context) => AuthorityRegisterScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(250, 50),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Register as Authority'),
              ),
              const SizedBox(height: 10),
              // Authority Login Button
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    // !! ERROR THIK KELA !! - 'const' kadhun takla
                    MaterialPageRoute(
                        builder: (context) => AuthorityLoginScreen()),
                  );
                },
                child: const Text(
                  'Login as Authority',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

