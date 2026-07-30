import 'package:flutter/material.dart';
import '../../models/staff.dart';
import '../../services/api_service.dart';

class MyProfileScreen extends StatefulWidget {
  final ApiService apiService;
  const MyProfileScreen({super.key, required this.apiService});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  Staff? _staff;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final staff = await widget.apiService.getMyStaffProfile();
      setState(() => _staff = staff);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null || _staff == null
              ? Center(child: Text(_errorMessage ?? "Not found"))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_staff!.name, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text(_staff!.email, style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 12),
                            Text(_staff!.areaOfInterest.isNotEmpty
                                ? _staff!.areaOfInterest
                                : "No area of interest set yet"),
                            const SizedBox(height: 8),
                            Text(_staff!.bio.isNotEmpty ? _staff!.bio : "No bio set yet"),
                            const SizedBox(height: 12),
                            Chip(
                              label: Text(_staff!.acceptingStudents
                                  ? "Accepting students - ${_staff!.spotsRemaining}/${_staff!.maxCapacity} spots left"
                                  : "Not currently accepting students"),
                              backgroundColor: _staff!.acceptingStudents
                                  ? Colors.green.shade100
                                  : Colors.grey.shade300,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text("My Project Ideas", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    if (_staff!.projectIdeas.isEmpty) const Text("No project ideas added yet."),
                    for (final idea in _staff!.projectIdeas)
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(idea.title),
                          subtitle: Text(
                            "${idea.description}\n${idea.pastSubmissions.length} past submission(s) on record",
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          trailing: Chip(label: Text(idea.statusFlag)),
                        ),
                      ),
                  ],
                ),
    );
  }
}
