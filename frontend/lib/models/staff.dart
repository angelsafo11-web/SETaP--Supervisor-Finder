import 'project_idea.dart';

class Staff {
  final int staffId;
  final String name;
  final String email;
  final String bio;
  final String areaOfInterest;
  final bool acceptingStudents;
  final int maxCapacity;
  final int spotsRemaining;
  final List<ProjectIdea> projectIdeas;

  Staff({
    required this.staffId,
    required this.name,
    required this.email,
    required this.bio,
    required this.areaOfInterest,
    required this.acceptingStudents,
    required this.maxCapacity,
    required this.spotsRemaining,
    required this.projectIdeas,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      staffId: json['staff_id'],
      name: json['name'],
      email: json['email'],
      bio: json['bio'] ?? '',
      areaOfInterest: json['area_of_interest'] ?? '',
      acceptingStudents: json['accepting_students'] ?? false,
      maxCapacity: json['max_capacity'] ?? 0,
      spotsRemaining: json['spots_remaining'] ?? 0,
      projectIdeas: (json['project_ideas'] as List<dynamic>? ?? [])
          .map((idea) => ProjectIdea.fromJson(idea))
          .toList(),
    );
  }
}
