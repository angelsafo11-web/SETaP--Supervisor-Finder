import 'package:flutter/material.dart';
import '../../models/project_idea.dart';
import '../../services/api_service.dart';
import '../chat_screen.dart';

class MyStudentsScreen extends StatefulWidget {
  final ApiService apiService;
  const MyStudentsScreen({super.key, required this.apiService});

  @override
  State<MyStudentsScreen> createState() => _MyStudentsScreenState();
}

class _MyStudentsScreenState extends State<MyStudentsScreen> {
  List<InterestRequestModel> _accepted = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final requests = await widget.apiService.getPendingRequests(status: "Accepted");
      setState(() => _accepted = requests);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Students")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _accepted.isEmpty
                  ? const Center(child: Text("You don't have any confirmed students yet."))
                  : ListView.builder(
                      itemCount: _accepted.length,
                      itemBuilder: (context, index) {
                        final request = _accepted[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(request.studentName.isNotEmpty
                                ? request.studentName
                                : "Student #${request.studentId}"),
                            subtitle: Text(request.projectTitle.isNotEmpty
                                ? request.projectTitle
                                : "Project idea #${request.projectId}"),
                            trailing: FilledButton.icon(
                              icon: const Icon(Icons.chat_bubble_outline, size: 18),
                              label: const Text("Message"),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      apiService: widget.apiService,
                                      otherUserId: request.studentId,
                                      otherUserName: request.studentName.isNotEmpty
                                          ? request.studentName
                                          : "Student #${request.studentId}",
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
