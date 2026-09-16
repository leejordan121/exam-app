class QuestionResult {
  final String questionNumber;
  final String? correctAnswer;
  final String? studentAnswer;
  bool get isCorrect => correctAnswer != null && correctAnswer == studentAnswer;

  const QuestionResult({required this.questionNumber, this.correctAnswer, this.studentAnswer});
}

class GradingResult {
  final List<QuestionResult> questions;
  final int correctCount;
  final int totalQuestions;

  const GradingResult({required this.questions, required this.correctCount, required this.totalQuestions});

  double get percentage => totalQuestions == 0 ? 0 : (correctCount / totalQuestions) * 100;
}

class GradingService {
  /// Compares [studentAnswers] against [answerKey] question-by-question.
  /// Question numbers are the union of both maps' keys, sorted numerically,
  /// so unanswered/misread questions still show up for teacher review.
  static GradingResult grade({
    required Map<String, String> answerKey,
    required Map<String, String> studentAnswers,
  }) {
    final questionNumbers = {...answerKey.keys, ...studentAnswers.keys}.toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));

    final results = questionNumbers
        .map((q) => QuestionResult(
              questionNumber: q,
              correctAnswer: answerKey[q],
              studentAnswer: studentAnswers[q],
            ))
        .toList();

    final correctCount = results.where((r) => r.isCorrect).length;

    return GradingResult(
      questions: results,
      correctCount: correctCount,
      totalQuestions: answerKey.length,
    );
  }
}
