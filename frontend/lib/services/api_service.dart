import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/staff.dart';
import '../models/student.dart';
import '../models/project_idea.dart';

/// One file, one job: talk to the FastAPI backend.
/// Every screen calls methods on this class instead of writing
/// http requests directly - so if your backend's address ever changes,
/// you only update it here, in one place.
class ApiService {
  // IMPORTANT: 'localhost' means something different depending on where
  // the app is running:
  //   - Android emulator:      http://10.0.2.2:8000
  //   - iOS simulator:         http://127.0.0.1:8000
  //   - Chrome (flutter run -d chrome): http://127.0.0.1:8000
  //   - A real physical phone: your computer's actual network IP,
  //                            e.g. http://192.168.1.42:8000
  // Change this one line to match how you're running the app.
  static const String baseUrl = "http://127.0.0.1:8000";

  String? _token;
  String? _role;
  int? _userId;

  // ---------- Token storage (so you stay logged in) ----------

  Future<void> _saveSession(String token, String role) async {
    _token = token;
    _role = role;
    _userId = _extractUserId(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('role', role);
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    if (_token != null) _userId = _extractUserId(_token!);
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  bool get isLoggedIn => _token != null;
  String? get role => _role;
  int? get userId => _userId;

  /// A JWT has 3 parts separated by dots: header.payload.signature
  /// We only need to READ the payload here (to display data in the app),
  /// not verify it - the backend already verifies it on every request,
  /// so this is safe: worst case, a tampered ID just gets rejected by the server.
  int? _extractUserId(String token) {
    try {
      final payload = token.split('.')[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = jsonDecode(decoded);
      return int.parse(data['sub'].toString());
    } catch (_) {
      return null;
    }
  }

  Map<String, String> get _authHeaders => {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      };

  // ---------- Auth ----------

  Future<void> registerStaff(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register/staff"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );
    _throwIfError(response);
  }

  Future<void> registerStudent(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register/student"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );
    _throwIfError(response);
  }

  Future<void> login(String role, String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"role": role, "email": email, "password": password}),
    );
    _throwIfError(response);
    final data = jsonDecode(response.body);
    await _saveSession(data['access_token'], data['role']);
  }

  // ---------- Own profile (staff and student) ----------

  Future<Staff> getMyStaffProfile() async {
    final response = await http.get(
      Uri.parse("$baseUrl/staff/me"),
      headers: _authHeaders,
    );
    _throwIfError(response);
    return Staff.fromJson(jsonDecode(response.body));
  }

  Future<Student> getMyStudentProfile() async {
    final response = await http.get(
      Uri.parse("$baseUrl/students/me"),
      headers: _authHeaders,
    );
    _throwIfError(response);
    return Student.fromJson(jsonDecode(response.body));
  }

  Future<List<InterestRequestModel>> getMyRequests() async {
    final response = await http.get(
      Uri.parse("$baseUrl/students/my-requests"),
      headers: _authHeaders,
    );
    _throwIfError(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => InterestRequestModel.fromJson(json)).toList();
  }

  // ---------- UC1: Manage Project Ideas ----------

  Future<void> addProjectIdea(String title, String description, String requiredSkills) async {
    final response = await http.post(
      Uri.parse("$baseUrl/staff/projects"),
      headers: _authHeaders,
      body: jsonEncode({
        "title": title,
        "description": description,
        "required_skills": requiredSkills,
      }),
    );
    _throwIfError(response);
  }

  Future<void> editProjectIdea(int projectId, {String? title, String? description, String? requiredSkills}) async {
    final body = <String, dynamic>{};
    if (title != null) body["title"] = title;
    if (description != null) body["description"] = description;
    if (requiredSkills != null) body["required_skills"] = requiredSkills;

    final response = await http.put(
      Uri.parse("$baseUrl/staff/projects/$projectId"),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    _throwIfError(response);
  }

  Future<void> deleteProjectIdea(int projectId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/staff/projects/$projectId"),
      headers: _authHeaders,
    );
    _throwIfError(response);
  }

  // ---------- Past submissions (examples of previously supervised projects) ----------

  Future<void> addPastSubmission(
    int projectId, {
    required String title,
    String studentName = "",
    int? yearCompleted,
    String description = "",
    String link = "",
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/staff/projects/$projectId/submissions"),
      headers: _authHeaders,
      body: jsonEncode({
        "title": title,
        "student_name": studentName,
        "year_completed": yearCompleted,
        "description": description,
        "link": link,
      }),
    );
    _throwIfError(response);
  }

  Future<void> deletePastSubmission(int submissionId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/staff/submissions/$submissionId"),
      headers: _authHeaders,
    );
    _throwIfError(response);
  }

  // ---------- UC2: Update Availability ----------

  Future<void> updateAvailability({bool? acceptingStudents, int? maxCapacity}) async {
    final body = <String, dynamic>{};
    if (acceptingStudents != null) body["accepting_students"] = acceptingStudents;
    if (maxCapacity != null) body["max_capacity"] = maxCapacity;

    final response = await http.put(
      Uri.parse("$baseUrl/staff/availability"),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    _throwIfError(response);
  }

  // ---------- UC3: Browse and Filter Staff Profiles ----------

  Future<List<Staff>> browseStaff({String? interest, bool acceptingOnly = false}) async {
    final params = <String, String>{};
    if (interest != null && interest.isNotEmpty) params["interest"] = interest;
    if (acceptingOnly) params["accepting_only"] = "true";

    final uri = Uri.parse("$baseUrl/students/browse").replace(queryParameters: params);
    final response = await http.get(uri, headers: _authHeaders);
    _throwIfError(response);

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Staff.fromJson(json)).toList();
  }

  Future<Staff> viewStaffProfile(int staffId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/students/staff/$staffId"),
      headers: _authHeaders,
    );
    _throwIfError(response);
    return Staff.fromJson(jsonDecode(response.body));
  }

  // A staff member viewing their OWN profile reuses the same public route above -
  // there's no separate "my profile" endpoint yet, so we just pass their own ID.
  Future<Staff> viewOwnStaffProfile(int staffId) => viewStaffProfile(staffId);

  // ---------- UC4: Express Interest in an Idea ----------

  Future<void> expressInterest(int projectId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/students/express-interest"),
      headers: _authHeaders,
      body: jsonEncode({"project_id": projectId}),
    );
    _throwIfError(response);
  }

  // ---------- UC5: Respond to Student Interest ----------

  Future<List<InterestRequestModel>> getPendingRequests() async {
    final response = await http.get(
      Uri.parse("$baseUrl/staff/requests"),
      headers: _authHeaders,
    );
    _throwIfError(response);

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => InterestRequestModel.fromJson(json)).toList();
  }

  Future<void> respondToRequest(int requestId, String decision) async {
    final response = await http.post(
      Uri.parse("$baseUrl/staff/requests/$requestId/respond"),
      headers: _authHeaders,
      body: jsonEncode({"decision": decision}),
    );
    _throwIfError(response);
  }

  // ---------- Shared error handling ----------

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 400) {
      // FastAPI puts the useful message under "detail" - we surface that
      // directly so the screen can show a helpful error to the user.
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? 'Something went wrong (${response.statusCode})');
      } catch (_) {
        throw Exception('Something went wrong (${response.statusCode})');
      }
    }
  }
}
