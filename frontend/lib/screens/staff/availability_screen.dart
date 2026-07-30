import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AvailabilityScreen extends StatefulWidget {
  final ApiService apiService;
  const AvailabilityScreen({super.key, required this.apiService});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  bool _acceptingStudents = true;
  int _maxCapacity = 3;
  int _spotsRemaining = 3;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    setState(() => _isLoading = true);
    try {
      final staffId = widget.apiService.userId;
      if (staffId == null) throw Exception("Not logged in");
      final staff = await widget.apiService.viewOwnStaffProfile(staffId);
      setState(() {
        _acceptingStudents = staff.acceptingStudents;
        _maxCapacity = staff.maxCapacity;
        _spotsRemaining = staff.spotsRemaining;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      // Alternative flow (new max below current confirmed students) is
      // handled server-side - if it fails, the error message below shows it.
      await widget.apiService.updateAvailability(
        acceptingStudents: _acceptingStudents,
        maxCapacity: _maxCapacity,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Availability updated")),
      );
      _loadCurrentStatus();
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Availability")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    title: const Text("Accepting students"),
                    subtitle: Text("Currently $_spotsRemaining spots remaining"),
                    value: _acceptingStudents,
                    onChanged: (value) => setState(() => _acceptingStudents = value),
                  ),
                  const SizedBox(height: 16),
                  Text("Maximum capacity: $_maxCapacity"),
                  Slider(
                    value: _maxCapacity.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: "$_maxCapacity",
                    onChanged: (value) => setState(() => _maxCapacity = value.round()),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    ),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving ? const CircularProgressIndicator() : const Text("Save"),
                  ),
                ],
              ),
            ),
    );
  }
}
