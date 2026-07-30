// Each class here mirrors a schema from your backend's schemas.py.
// fromJson() converts the raw JSON your API sends back into a proper Dart object.

class ProjectIdea {
  final int projectId;
  final int staffId;
  final String title;
  final String description;
  final String requiredSkills;
  final String statusFlag;

  ProjectIdea({
    required this.projectId,
    required this.staffId,
    required this.title,
    required this.description,
    required this.requiredSkills,
    required this.statusFlag,
  });

  factory ProjectIdea.fromJson(Map<String, dynamic> json) {
    return ProjectIdea(
      projectId: json['project_id'],
      staffId: json['staff_id'],
      title: json['title'],
      description: json['description'],
      requiredSkills: json['required_skills'] ?? '',
      statusFlag: json['status_flag'] ?? 'Open',
    );
  }
}

class InterestRequestModel {
  final int requestId;
  final int staffId;
  final int studentId;
  final int projectId;
  final String requestStatus;

  InterestRequestModel({
    required this.requestId,
    required this.staffId,
    required this.studentId,
    required this.projectId,
    required this.requestStatus,
  });

  factory InterestRequestModel.fromJson(Map<String, dynamic> json) {
    return InterestRequestModel(
      requestId: json['request_id'],
      staffId: json['staff_id'],
      studentId: json['student_id'],
      projectId: json['project_id'],
      requestStatus: json['request_status'],
    );
  }
}

