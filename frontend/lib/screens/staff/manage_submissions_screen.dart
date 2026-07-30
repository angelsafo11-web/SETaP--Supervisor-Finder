import 'package:flutter/material.dart';
import '../../models/project_idea.dart';
import '../../services/api_service.dart';

class ManageSubmissionsScreen extends StatefulWidget {
  final ApiService apiService;
  final ProjectIdea projectIdea;
  const ManageSubmissionsScreen({super.key, required this.apiService, required this.projectIdea});

  @override
  State<ManageSubmissionsScreen> createState() => _ManageSubmissionsScreenState();
}

class _ManageSubmissionsScreenState extends State<ManageSubmissionsScreen> {
  late List<PastSubmission> _submissions;

  @override
  void initState() {
    super.initState();
    _submissions = List.from(widget.projectIdea.pastSubmissions);
  }

  Future<void> _openAddForm() async {
    final titleController = TextEditingController();
    final studentController = TextEditingController();
    final yearController = TextEditingController();
    final descController = TextEditingController();
    final linkController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Past Submission"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Project title")),
              TextField(controller: studentController, decoration: const InputDecoration(labelText: "Student name")),
              TextField(
                controller: yearController,
                decoration: const InputDecoration(labelText: "Year completed"),
                keyboardType: TextInputType.number,
              ),
              TextField(controller: descController, decoration: const InputDecoration(labelText: "Description"), maxLines: 3),
              TextField(controller: linkController, decoration: const InputDecoration(labelText: "Link (optional)")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Save")),
        ],
      ),
    );

    if (saved != true) return;
    if (titleController.text.trim().isEmpty) return;

    try {
      await widget.apiService.addPastSubmission(
        widget.projectIdea.projectId,
        title: titleController.text.trim(),
        studentName: studentController.text.trim(),
        yearCompleted: int.tryParse(yearController.text.trim()),
        description: descController.text.trim(),
        link: linkController.text.trim(),
      );
      // Reload the parent project idea's full data to get the new submission with its real ID
      final staff = await widget.apiService.getMyStaffProfile();
      final updated = staff.projectIdeas.firstWhere((idea) => idea.projectId == widget.projectIdea.projectId);
      setState(() => _submissions = updated.pastSubmissions);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _delete(PastSubmission submission) async {
    try {
      await widget.apiService.deletePastSubmission(submission.submissionId);
      setState(() => _submissions.removeWhere((s) => s.submissionId == submission.submissionId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Past Submissions - ${widget.projectIdea.title}")),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddForm,
        child: const Icon(Icons.add),
      ),
      body: _submissions.isEmpty
          ? const Center(child: Text("No past submissions added yet."))
          : ListView.builder(
              itemCount: _submissions.length,
              itemBuilder: (context, index) {
                final submission = _submissions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(submission.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (submission.studentName.isNotEmpty || submission.yearCompleted != null)
                          Text([
                            if (submission.studentName.isNotEmpty) submission.studentName,
                            if (submission.yearCompleted != null) submission.yearCompleted.toString(),
                          ].join(" - ")),
                        if (submission.description.isNotEmpty) Text(submission.description),
                        if (submission.link.isNotEmpty)
                          Text(submission.link, style: const TextStyle(color: Colors.blue)),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _delete(submission),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
