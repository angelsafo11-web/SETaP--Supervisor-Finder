class MessageModel {
  final int messageId;
  final int staffId;
  final int studentId;
  final String senderRole;
  final String content;
  final DateTime timestamp;

  MessageModel({
    required this.messageId,
    required this.staffId,
    required this.studentId,
    required this.senderRole,
    required this.content,
    required this.timestamp,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['message_id'],
      staffId: json['staff_id'],
      studentId: json['student_id'],
      senderRole: json['sender_role'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
