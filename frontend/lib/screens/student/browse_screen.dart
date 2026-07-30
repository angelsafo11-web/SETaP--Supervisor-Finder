import 'package:flutter/material.dart';
import '../../models/staff.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import 'staff_profile_screen.dart';
import 'student_profile_screen.dart';

class BrowseScreen extends StatefulWidget {
  final ApiService apiService;
  const BrowseScreen({super.key, required this.apiService});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _searchController = TextEditingController();
  bool _acceptingOnly = false;
  List<Staff> _results = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await widget.apiService.browseStaff(
        interest: _searchController.text.trim(),
        acceptingOnly: _acceptingOnly,
      );
      setState(() => _results = results);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find a Supervisor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: "My Profile",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StudentProfileScreen(apiService: widget.apiService),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Log out",
        onPressed: () async {
          await widget.apiService.logout();
          if (!context.mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => LoginScreen(apiService: widget.apiService)),
            (route) => false,
          );
        },
        child: const Icon(Icons.logout),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: "Filter by interest (e.g. AI)",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _loadStaff,
                    ),
                  ),
                  onSubmitted: (_) => _loadStaff(),
                ),
                CheckboxListTile(
                  title: const Text("Only show staff accepting students"),
                  value: _acceptingOnly,
                  onChanged: (value) {
                    setState(() => _acceptingOnly = value ?? false);
                    _loadStaff();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!));
    if (_results.isEmpty) {
      // Matches your UC3 "no results" alternative flow
      return const Center(child: Text("No staff match your filters."));
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final staff = _results[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(staff.name),
            subtitle: Text(staff.areaOfInterest.isNotEmpty
                ? staff.areaOfInterest
                : "No listed area of interest"),
            trailing: Chip(
              label: Text(staff.acceptingStudents
                  ? "${staff.spotsRemaining} spots left"
                  : "Not accepting"),
              backgroundColor: staff.acceptingStudents
                  ? Colors.green.shade100
                  : Colors.grey.shade300,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StaffProfileScreen(
                    apiService: widget.apiService,
                    staffId: staff.staffId,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
