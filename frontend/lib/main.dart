import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/staff/staff_dashboard_screen.dart';
import 'screens/student/browse_screen.dart';

void main() {
  runApp(const SupervisorFinderApp());
}

class SupervisorFinderApp extends StatefulWidget {
  const SupervisorFinderApp({super.key});

  @override
  State<SupervisorFinderApp> createState() => _SupervisorFinderAppState();
}

class _SupervisorFinderAppState extends State<SupervisorFinderApp> {
  // One shared ApiService instance, passed down to every screen,
  // so they all share the same login session.
  final ApiService _apiService = ApiService();
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    await _apiService.loadSession();
    setState(() => _isCheckingSession = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supervisor Finder',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: _isCheckingSession
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _buildStartScreen(),
    );
  }

  Widget _buildStartScreen() {
    // If a saved session exists, skip straight to the right dashboard
    if (_apiService.isLoggedIn) {
      if (_apiService.role == "staff") {
        return StaffDashboardScreen(apiService: _apiService);
      }
      return BrowseScreen(apiService: _apiService);
    }
    return LoginScreen(apiService: _apiService);
  }
}