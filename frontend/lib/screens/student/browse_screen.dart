import 'package:flutter/material.dart';
import '../../models/project_idea.dart';
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
  List<ProjectIdeaWithStaff> _results = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _checkSupervisorReminder();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await widget.apiService.browseProjects(
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

  // Reminds the student to keep looking for a supervisor if none of their
  // interest requests has been Accepted yet.
  Future<void> _checkSupervisorReminder() async {
    try {
      final requests = await widget.apiService.getMyRequests();
      final hasAccepted = requests.any((r) => r.requestStatus == "Accepted");
      if (!hasAccepted && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Still looking for a supervisor?"),
              content: Text(requests.isEmpty
                  ? "You haven't expressed interest in any project yet. Browse ideas below to get started."
                  : "You have ${requests.length} pending request(s), but none have been accepted yet. "
                      "Consider browsing more project ideas in case your first choices don't work out."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Got it")),
              ],
            ),
          );
        });
      }
    } catch (_) {
      // Non-critical - if this check fails, just skip the reminder silently.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Browse Project Ideas"),
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
                    labelText: "Search by idea title, description, or interest",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _loadProjects,
                    ),
                  ),
                  onSubmitted: (_) => _loadProjects(),
                ),
                CheckboxListTile(
                  title: const Text("Only show staff accepting students"),
                  value: _acceptingOnly,
                  onChanged: (value) {
                    setState(() => _acceptingOnly = value ?? false);
                    _loadProjects();
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
      return const Center(child: Text("No project ideas match your filters."));
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final idea = _results[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(idea.title),
            subtitle: Text("By ${idea.staffName}"
                "${idea.requiredSkills.isNotEmpty ? ' - Skills: ${idea.requiredSkills}' : ''}"),
            trailing: Chip(
              label: Text(idea.statusFlag == "Taken"
                  ? "Taken"
                  : idea.staffAcceptingStudents
                      ? "${idea.staffSpotsRemaining} spots left"
                      : "Not accepting"),
              backgroundColor: (idea.statusFlag == "Open" && idea.staffAcceptingStudents)
                  ? Colors.green.shade100
                  : Colors.grey.shade300,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StaffProfileScreen(
                    apiService: widget.apiService,
                    staffId: idea.staffId,
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
