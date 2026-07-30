import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import 'manage_projects_screen.dart';
import 'availability_screen.dart';
import 'requests_screen.dart';
import 'my_profile_screen.dart';

class StaffDashboardScreen extends StatelessWidget {
  final ApiService apiService;
  const StaffDashboardScreen({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Staff Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await apiService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => LoginScreen(apiService: apiService)),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DashboardTile(
            icon: Icons.person,
            title: "My Profile",
            subtitle: "View your own details and project ideas",
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MyProfileScreen(apiService: apiService)),
            ),
          ),
          _DashboardTile(
            icon: Icons.lightbulb_outline,
            title: "Manage Project Ideas",
            subtitle: "Add, edit, or remove your project ideas (UC1)",
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ManageProjectsScreen(apiService: apiService)),
            ),
          ),
          _DashboardTile(
            icon: Icons.event_available,
            title: "Update Availability",
            subtitle: "Toggle accepting students and set capacity (UC2)",
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AvailabilityScreen(apiService: apiService)),
            ),
          ),
          _DashboardTile(
            icon: Icons.inbox,
            title: "Student Requests",
            subtitle: "Accept or decline interest requests (UC5)",
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => RequestsScreen(apiService: apiService)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
