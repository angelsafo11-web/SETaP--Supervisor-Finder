import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../models/staff.dart';
import '../../models/project_idea.dart';
import '../../services/api_service.dart';
import '../chat_screen.dart';

/// A little extra info attached to each request just for display -
/// the backend only gives us IDs, so we look up the staff member
/// and matching project idea ourselves to show a readable title/name.
class _RequestDisplay {
  final InterestRequestModel request;
  final String staffName;
  final String projectTitle;
  _RequestDisplay({required this.request, required this.staffName, required this.projectTitle});
}

class StudentProfileScreen extends StatefulWidget {
  final ApiService apiService;
  const StudentProfileScreen({super.key, required this.apiService});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  Student? _student;
  List<_RequestDisplay> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    setState(() => _isLoading = true);
    try {
      final student = await widget.apiService.getMyStudentProfile();
      final rawRequests = await widget.apiService.getMyRequests();

      // Look up each request's staff member/project title.
      // Caches staff profiles by ID so we don't re-fetch the same one twice.
      final staffCache = <int, Staff>{};
      final enriched = <_RequestDisplay>[];

      for (final request in rawRequests) {
        Staff staff;
        if (staffCache.containsKey(request.staffId)) {
          staff = staffCache[request.staffId]!;
        } else {
          staff = await widget.apiService.viewStaffProfile(request.staffId);
          staffCache[request.staffId] = staff;
        }

        final matchingIdea = staff.projectIdeas.where((idea) => idea.projectId == request.projectId);
        final title = matchingIdea.isNotEmpty ? matchingIdea.first.title : "Project #${request.projectId}";

        enriched.add(_RequestDisplay(request: request, staffName: staff.name, projectTitle: title));
      }

      setState(() {
        _student = student;
        _requests = enriched;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Maps a request's status to a simple "stage" description and colour,
  // so it's clear at a glance where each application stands.
  (String, Color) _stageFor(String status) {
    switch (status) {
      case "Accepted":
        return ("Confirmed - supervision secured", Colors.green);
      case "Declined":
        return ("Not successful", Colors.red);
      default:
        return ("Awaiting staff response", Colors.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_student?.name ?? "", style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text(_student?.email ?? "", style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text("My Expressed Interests", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    if (_requests.isEmpty) const Text("You haven't expressed interest in any project yet."),
                    for (final item in _requests)
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(item.projectTitle),
                              subtitle: Text("Supervisor: ${item.staffName}"),
                              trailing: Builder(builder: (context) {
                                final (label, color) = _stageFor(item.request.requestStatus);
                                return Chip(
                                  label: Text(label, style: const TextStyle(fontSize: 12)),
                                  backgroundColor: color.withOpacity(0.15),
                                  labelStyle: TextStyle(color: color),
                                );
                              }),
                            ),
                            if (item.request.requestStatus == "Accepted")
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                    label: const Text("Message supervisor"),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            apiService: widget.apiService,
                                            otherUserId: item.request.staffId,
                                            otherUserName: item.staffName,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
