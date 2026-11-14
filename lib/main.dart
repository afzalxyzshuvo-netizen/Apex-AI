import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ApexAIApp());
}

class ApexAIApp extends StatefulWidget {
  const ApexAIApp({super.key});

  @override
  State<ApexAIApp> createState() => _ApexAIAppState();
}

class _ApexAIAppState extends State<ApexAIApp> {
  bool _isLoggedIn = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      _isChecking = false;
    });
  }

  void _onLoginSuccess() {
    setState(() => _isLoggedIn = true);
  }

  void _onLogout() {
    setState(() => _isLoggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apex AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E17),
        primaryColor: const Color(0xFFFFB800),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFB800),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF131B2A),
        ),
        fontFamily: 'Roboto',
      ),
      home: _isChecking
          ? const Scaffold(
              backgroundColor: Color(0xFF0A0E17),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFFFB800)),
              ),
            )
          : (_isLoggedIn
              ? MainNavigationScreen(onLogout: _onLogout)
              : LoginScreen(onLoginSuccess: _onLoginSuccess)),
    );
  }
}
