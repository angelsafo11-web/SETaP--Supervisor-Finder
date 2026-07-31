import 'package:flutter/material.dart';
import '../../models/project_idea.dart';
import '../../services/api_service.dart';

class RequestsScreen extends StatefulWidget {
  final ApiService apiService;
  const RequestsScreen({super.key, required this.apiService});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  List<InterestRequestModel> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await widget.apiService.getPendingRequests();
      setState(() => _requests = requests);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _respond(InterestRequestModel request, String decision) async {
    try {
      // Alternative flow (already at full capacity) is handled server-side -
      // if it fails, the SnackBar below shows the reason.
      await widget.apiService.respondToRequest(request.requestId, decision);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request $decision" "ed")),
      );
      _loadRequests();
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
      appBar: AppBar(title: const Text("Student Requests")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _requests.isEmpty
                  ? const Center(child: Text("No pending requests right now."))
                  : ListView.builder(
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final request = _requests[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            title: Text(request.studentName.isNotEmpty
                                ? request.studentName
                                : "Student #${request.studentId}"),
                            subtitle: Text(request.projectTitle.isNotEmpty
                                ? "${request.projectTitle} - ${request.requestStatus}"
                                : "Project idea #${request.projectId} - ${request.requestStatus}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => _respond(request, "accept"),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => _respond(request, "decline"),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
