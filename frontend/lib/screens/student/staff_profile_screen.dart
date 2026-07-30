import 'package:flutter/material.dart';
import '../../models/staff.dart';
import '../../models/project_idea.dart';
import '../../services/api_service.dart';

class StaffProfileScreen extends StatefulWidget {
  final ApiService apiService;
  final int staffId;
  const StaffProfileScreen({super.key, required this.apiService, required this.staffId});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
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
      final staff = await widget.apiService.viewStaffProfile(widget.staffId);
      setState(() => _staff = staff);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _expressInterest(ProjectIdea idea) async {
    try {
      await widget.apiService.expressInterest(idea.projectId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Interest submitted! Status: Pending")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null || _staff == null) {
      return Scaffold(body: Center(child: Text(_errorMessage ?? "Not found")));
    }

    final staff = _staff!;

    return Scaffold(
      appBar: AppBar(title: Text(staff.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(staff.areaOfInterest, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(staff.bio.isNotEmpty ? staff.bio : "No bio provided."),
          const SizedBox(height: 8),
          Chip(
            label: Text(staff.acceptingStudents
                ? "Accepting students - ${staff.spotsRemaining} spots left"
                : "Not currently accepting students"),
            backgroundColor: staff.acceptingStudents
                ? Colors.green.shade100
                : Colors.grey.shade300,
          ),
          const Divider(height: 32),
          Text("Project ideas", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (staff.projectIdeas.isEmpty) const Text("No project ideas listed yet."),
          for (final idea in staff.projectIdeas)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(idea.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(idea.description),
                    if (idea.requiredSkills.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text("Skills: ${idea.requiredSkills}",
                          style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                    if (idea.pastSubmissions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text("Past student projects on this idea:",
                          style: Theme.of(context).textTheme.labelLarge),
                      for (final submission in idea.pastSubmissions)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("• ${submission.title}"
                                  "${submission.yearCompleted != null ? ' (${submission.yearCompleted})' : ''}"),
                              if (submission.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Text(submission.description,
                                      style: Theme.of(context).textTheme.bodySmall),
                                ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        // Alternative flow: staff not accepting, or idea already taken
                        onPressed: (staff.acceptingStudents && idea.statusFlag == "Open")
                            ? () => _expressInterest(idea)
                            : null,
                        child: Text(idea.statusFlag == "Taken" ? "Already taken" : "Express Interest"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
