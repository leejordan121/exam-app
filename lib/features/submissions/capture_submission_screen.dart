import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../exams/exam_model.dart';
import '../grading/ocr_service.dart';

class CaptureSubmissionScreen extends StatefulWidget {
  final Exam exam;

  const CaptureSubmissionScreen({super.key, required this.exam});

  @override
  State<CaptureSubmissionScreen> createState() => _CaptureSubmissionScreenState();
}

class _CaptureSubmissionScreenState extends State<CaptureSubmissionScreen> {
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  File? _photo;
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 90);
    if (picked == null) return;
    setState(() => _photo = File(picked.path));
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    setState(() => _photo = File(picked.path));
  }

  Future<void> _continue() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = "Enter the student's name");
      return;
    }
    if (_photo == null) {
      setState(() => _error = "Take or choose a photo of the student's paper");
      return;
    }
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final ocr = OcrService();
      Map<String, String> detected;
      try {
        detected = await ocr.extractAnswers(_photo!);
      } finally {
        ocr.dispose();
      }
      if (!mounted) return;
      context.pushReplacement(
        '/exams/${widget.exam.id}/submissions/review',
        extra: {
          'exam': widget.exam,
          'photo': _photo,
          'studentName': _nameController.text.trim(),
          'rollNumber': _rollController.text.trim().isEmpty ? null : _rollController.text.trim(),
          'detectedAnswers': detected,
        },
      );
    } catch (e) {
      setState(() => _error = 'Could not read the photo: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Student Paper')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Student name"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rollController,
            decoration: const InputDecoration(labelText: 'Roll number (optional)'),
          ),
          const SizedBox(height: 20),
          if (_photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(_photo!, height: 220, fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _processing ? null : _continue,
            child: _processing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Read Answers & Continue'),
          ),
        ],
      ),
    );
  }
}
