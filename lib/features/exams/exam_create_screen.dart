import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';
import '../grading/ocr_service.dart';
import 'exam_repository.dart';

const _imageExtensions = ['jpg', 'jpeg', 'png'];

class ExamCreateScreen extends ConsumerStatefulWidget {
  const ExamCreateScreen({super.key});

  @override
  ConsumerState<ExamCreateScreen> createState() => _ExamCreateScreenState();
}

class _ExamCreateScreenState extends ConsumerState<ExamCreateScreen> {
  final _titleController = TextEditingController();
  File? _questionPaper;
  String? _questionPaperName;
  File? _answerKeyFile;
  String? _answerKeyName;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickQuestionPaper() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    if (files.isEmpty || files.single.path == null) return;
    setState(() {
      _questionPaper = File(files.single.path!);
      _questionPaperName = files.single.name;
    });
  }

  Future<void> _pickAnswerKey() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    if (files.isEmpty || files.single.path == null) return;
    setState(() {
      _answerKeyFile = File(files.single.path!);
      _answerKeyName = files.single.name;
    });
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Enter an exam title');
      return;
    }
    if (_questionPaper == null || _answerKeyFile == null) {
      setState(() => _error = 'Upload both the question paper and the answer key');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final teacherId = ref.read(currentUserProvider)!.id;
      final repo = ref.read(examRepositoryProvider);
      final exam = await repo.createExam(teacherId: teacherId, title: _titleController.text.trim());

      await repo.uploadQuestionPaper(
        teacherId: teacherId,
        examId: exam.id,
        file: _questionPaper!,
        fileName: _questionPaperName!,
      );
      await repo.uploadAnswerKeyFile(
        teacherId: teacherId,
        examId: exam.id,
        file: _answerKeyFile!,
        fileName: _answerKeyName!,
      );

      Map<String, String> detectedAnswers = {};
      final ext = _answerKeyName!.split('.').last.toLowerCase();
      if (_imageExtensions.contains(ext)) {
        final ocr = OcrService();
        try {
          detectedAnswers = await ocr.extractAnswers(_answerKeyFile!);
        } finally {
          ocr.dispose();
        }
      }

      if (!mounted) return;
      context.pushReplacement('/exams/${exam.id}/answer-key', extra: detectedAnswers);
    } catch (e) {
      setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Exam')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Exam title'),
          ),
          const SizedBox(height: 20),
          _FilePickTile(
            label: 'Question paper',
            fileName: _questionPaperName,
            onTap: _pickQuestionPaper,
          ),
          const SizedBox(height: 12),
          _FilePickTile(
            label: 'Answer key',
            fileName: _answerKeyName,
            onTap: _pickAnswerKey,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create & Continue'),
          ),
        ],
      ),
    );
  }
}

class _FilePickTile extends StatelessWidget {
  final String label;
  final String? fileName;
  final VoidCallback onTap;

  const _FilePickTile({required this.label, required this.fileName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.upload_file),
        title: Text(label),
        subtitle: Text(fileName ?? 'No file selected'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
