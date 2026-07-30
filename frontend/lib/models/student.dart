class Student {
  final int studentId;
  final String name;
  final String email;

  Student({required this.studentId, required this.name, required this.email});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: json['student_id'],
      name: json['name'],
      email: json['email'],
    );
  }
}
