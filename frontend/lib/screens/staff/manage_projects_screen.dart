import 'package:flutter/material.dart';
import '../../models/project_idea.dart';
import '../../services/api_service.dart';
import 'manage_submissions_screen.dart';

class ManageProjectsScreen extends StatefulWidget {
  final ApiService apiService;
  const ManageProjectsScreen({super.key, required this.apiService});

  @override
  State<ManageProjectsScreen> createState() => _ManageProjectsScreenState();
}

class _ManageProjectsScreenState extends State<ManageProjectsScreen> {
  List<ProjectIdea> _ideas = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadIdeas();
  }

  Future<void> _loadIdeas() async {
    setState(() => _isLoading = true);
    try {
      final staff = await widget.apiService.getMyStaffProfile();
      setState(() => _ideas = staff.projectIdeas);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openIdeaForm({ProjectIdea? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? "");
    final descController = TextEditingController(text: existing?.description ?? "");
    final skillsController = TextEditingController(text: existing?.requiredSkills ?? "");

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? "Add Project Idea" : "Edit Project Idea"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: descController, decoration: const InputDecoration(labelText: "Description"), maxLines: 3),
            TextField(controller: skillsController, decoration: const InputDecoration(labelText: "Required skills")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Save")),
        ],
      ),
    );

    if (saved != true) return;

    try {
      if (existing == null) {
        await widget.apiService.addProjectIdea(
          titleController.text.trim(),
          descController.text.trim(),
          skillsController.text.trim(),
        );
      } else {
        await widget.apiService.editProjectIdea(
          existing.projectId,
          title: titleController.text.trim(),
          description: descController.text.trim(),
          requiredSkills: skillsController.text.trim(),
        );
      }
      _loadIdeas();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _deleteIdea(ProjectIdea idea) async {
    // Alternative flow: confirm before deleting
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete this idea?"),
        content: Text("\"${idea.title}\" will be permanently removed."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.apiService.deleteProjectIdea(idea.projectId);
      _loadIdeas();
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
      appBar: AppBar(title: const Text("Manage Project Ideas")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openIdeaForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _ideas.isEmpty
                  ? const Center(child: Text("You haven't added any project ideas yet."))
                  : ListView.builder(
                      itemCount: _ideas.length,
                      itemBuilder: (context, index) {
                        final idea = _ideas[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(idea.title),
                                subtitle: Text(idea.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Chip(label: Text(idea.statusFlag)),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _openIdeaForm(existing: idea),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteIdea(idea),
                                    ),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.history_edu, size: 18),
                                    label: Text("Past submissions (${idea.pastSubmissions.length})"),
                                    onPressed: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ManageSubmissionsScreen(
                                            apiService: widget.apiService,
                                            projectIdea: idea,
                                          ),
                                        ),
                                      );
                                      // Refresh in case submissions were added/removed
                                      _loadIdeas();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
