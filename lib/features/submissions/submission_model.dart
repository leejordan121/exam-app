class Submission {
  final String id;
  final String examId;
  final String studentName;
  final String? rollNumber;
  final String? photoPath;
  final Map<String, String> detectedAnswers;
  final Map<String, String> finalAnswers;
  final num? score;
  final int totalQuestions;
  final bool graded;
  final DateTime createdAt;

  const Submission({
    required this.id,
    required this.examId,
    required this.studentName,
    required this.rollNumber,
    required this.photoPath,
    required this.detectedAnswers,
    required this.finalAnswers,
    required this.score,
    required this.totalQuestions,
    required this.graded,
    required this.createdAt,
  });

  factory Submission.fromMap(Map<String, dynamic> map) {
    final detected = (map['detected_answers'] as Map?) ?? const {};
    final finalAns = (map['final_answers'] as Map?) ?? const {};
    return Submission(
      id: map['id'] as String,
      examId: map['exam_id'] as String,
      studentName: map['student_name'] as String,
      rollNumber: map['roll_number'] as String?,
      photoPath: map['photo_path'] as String?,
      detectedAnswers: detected.map((k, v) => MapEntry(k.toString(), v.toString())),
      finalAnswers: finalAns.map((k, v) => MapEntry(k.toString(), v.toString())),
      score: map['score'] as num?,
      totalQuestions: (map['total_questions'] as num?)?.toInt() ?? 0,
      graded: map['graded'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
