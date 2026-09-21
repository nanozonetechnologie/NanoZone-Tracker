import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './login_screen.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  void _completeSetup(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_complete', true);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to NanoZone Budget Tracker!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Set your budget, track expenses, and stay in control.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _completeSetup(context),
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
