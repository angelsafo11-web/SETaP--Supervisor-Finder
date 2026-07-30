import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'staff/staff_dashboard_screen.dart';
import 'student/browse_screen.dart';

class LoginScreen extends StatefulWidget {
  final ApiService apiService;
  const LoginScreen({super.key, required this.apiService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = "student"; // which toggle is selected
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.apiService.login(
        _role,
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // Send the user to the correct dashboard based on their role
      if (_role == "staff") {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StaffDashboardScreen(apiService: widget.apiService),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BrowseScreen(apiService: widget.apiService),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Supervisor Finder - Log In")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Role toggle: this decides which /auth/login "role" gets sent
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: "student", label: Text("Student")),
                ButtonSegment(value: "staff", label: Text("Staff")),
              ],
              selected: {_role},
              onSelectionChanged: (selection) {
                setState(() => _role = selection.first);
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            FilledButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Log In"),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RegisterScreen(apiService: widget.apiService),
                  ),
                );
              },
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}
