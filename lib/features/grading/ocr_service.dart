import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Parses "1. A", "Q2) C", "12 - D" style lines out of recognized text into
/// a question-number -> answer-letter map. This is a best-effort OCR pass;
/// the caller is expected to show the result to the teacher for review
/// before it's treated as ground truth.
class OcrService {
  static final RegExp _answerLinePattern =
      RegExp(r'^\s*(?:Q\.?\s*)?(\d{1,3})\s*[\.\)\-:]?\s*([ABCDabcd])\s*$');

  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<Map<String, String>> extractAnswers(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _recognizer.processImage(inputImage);

    final answers = <String, String>{};
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final match = _answerLinePattern.firstMatch(line.text.trim());
        if (match != null) {
          final questionNumber = match.group(1)!;
          final letter = match.group(2)!.toUpperCase();
          answers[questionNumber] = letter;
        }
      }
    }
    return answers;
  }

  void dispose() {
    _recognizer.close();
  }
}
