class Exam {
  final String id;
  final String teacherId;
  final String title;
  final String? questionPaperPath;
  final String? answerKeyPath;
  final Map<String, String> answerKey;
  final int totalQuestions;
  final String status; // draft, ready, active, closed
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? closedAt;

  const Exam({
    required this.id,
    required this.teacherId,
    required this.title,
    required this.questionPaperPath,
    required this.answerKeyPath,
    required this.answerKey,
    required this.totalQuestions,
    required this.status,
    required this.createdAt,
    required this.startedAt,
    required this.closedAt,
  });

  factory Exam.fromMap(Map<String, dynamic> map) {
    final rawKey = (map['answer_key'] as Map?) ?? const {};
    return Exam(
      id: map['id'] as String,
      teacherId: map['teacher_id'] as String,
      title: map['title'] as String,
      questionPaperPath: map['question_paper_path'] as String?,
      answerKeyPath: map['answer_key_path'] as String?,
      answerKey: rawKey.map((k, v) => MapEntry(k.toString(), v.toString())),
      totalQuestions: (map['total_questions'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'draft',
      createdAt: DateTime.parse(map['created_at'] as String),
      startedAt: map['started_at'] == null ? null : DateTime.parse(map['started_at'] as String),
      closedAt: map['closed_at'] == null ? null : DateTime.parse(map['closed_at'] as String),
    );
  }

  bool get isReady => status != 'draft';
  bool get isActive => status == 'active';
  bool get isClosed => status == 'closed';
}
