// Each class here mirrors a schema from your backend's schemas.py.
// fromJson() converts the raw JSON your API sends back into a proper Dart object.

class PastSubmission {
  final int submissionId;
  final int projectId;
  final String title;
  final String studentName;
  final int? yearCompleted;
  final String description;
  final String link;

  PastSubmission({
    required this.submissionId,
    required this.projectId,
    required this.title,
    required this.studentName,
    required this.yearCompleted,
    required this.description,
    required this.link,
  });

  factory PastSubmission.fromJson(Map<String, dynamic> json) {
    return PastSubmission(
      submissionId: json['submission_id'],
      projectId: json['project_id'],
      title: json['title'],
      studentName: json['student_name'] ?? '',
      yearCompleted: json['year_completed'],
      description: json['description'] ?? '',
      link: json['link'] ?? '',
    );
  }
}

class ProjectIdea {
  final int projectId;
  final int staffId;
  final String title;
  final String description;
  final String requiredSkills;
  final String statusFlag;
  final List<PastSubmission> pastSubmissions;

  ProjectIdea({
    required this.projectId,
    required this.staffId,
    required this.title,
    required this.description,
    required this.requiredSkills,
    required this.statusFlag,
    required this.pastSubmissions,
  });

  factory ProjectIdea.fromJson(Map<String, dynamic> json) {
    return ProjectIdea(
      projectId: json['project_id'],
      staffId: json['staff_id'],
      title: json['title'],
      description: json['description'],
      requiredSkills: json['required_skills'] ?? '',
      statusFlag: json['status_flag'] ?? 'Open',
      pastSubmissions: (json['past_submissions'] as List<dynamic>? ?? [])
          .map((s) => PastSubmission.fromJson(s))
          .toList(),
    );
  }
}

class ProjectIdeaWithStaff {
  final int projectId;
  final int staffId;
  final String title;
  final String description;
  final String requiredSkills;
  final String statusFlag;
  final List<PastSubmission> pastSubmissions;
  final String staffName;
  final bool staffAcceptingStudents;
  final int staffSpotsRemaining;

  ProjectIdeaWithStaff({
    required this.projectId,
    required this.staffId,
    required this.title,
    required this.description,
    required this.requiredSkills,
    required this.statusFlag,
    required this.pastSubmissions,
    required this.staffName,
    required this.staffAcceptingStudents,
    required this.staffSpotsRemaining,
  });

  factory ProjectIdeaWithStaff.fromJson(Map<String, dynamic> json) {
    return ProjectIdeaWithStaff(
      projectId: json['project_id'],
      staffId: json['staff_id'],
      title: json['title'],
      description: json['description'],
      requiredSkills: json['required_skills'] ?? '',
      statusFlag: json['status_flag'] ?? 'Open',
      pastSubmissions: (json['past_submissions'] as List<dynamic>? ?? [])
          .map((s) => PastSubmission.fromJson(s))
          .toList(),
      staffName: json['staff_name'],
      staffAcceptingStudents: json['staff_accepting_students'] ?? false,
      staffSpotsRemaining: json['staff_spots_remaining'] ?? 0,
    );
  }
}

class InterestRequestModel {
  final int requestId;
  final int staffId;
  final int studentId;
  final int projectId;
  final String requestStatus;
  final String studentName;
  final String projectTitle;

  InterestRequestModel({
    required this.requestId,
    required this.staffId,
    required this.studentId,
    required this.projectId,
    required this.requestStatus,
    this.studentName = "",
    this.projectTitle = "",
  });

  factory InterestRequestModel.fromJson(Map<String, dynamic> json) {
    return InterestRequestModel(
      requestId: json['request_id'],
      staffId: json['staff_id'],
      studentId: json['student_id'],
      projectId: json['project_id'],
      requestStatus: json['request_status'],
      studentName: json['student_name'] ?? '',
      projectTitle: json['project_title'] ?? '',
    );
  }
}
