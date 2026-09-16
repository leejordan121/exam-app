import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';
import 'exam_model.dart';
import 'exam_repository.dart';

class ExamListScreen extends ConsumerStatefulWidget {
  const ExamListScreen({super.key});

  @override
  ConsumerState<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends ConsumerState<ExamListScreen> {
  late Future<List<Exam>> _examsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final teacherId = ref.read(currentUserProvider)!.id;
    _examsFuture = ref.read(examRepositoryProvider).listExams(teacherId);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _examsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Exams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/exams/new');
          _refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Exam'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Exam>>(
          future: _examsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text('Error: ${snapshot.error}'))]);
            }
            final exams = snapshot.data ?? [];
            if (exams.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No exams yet. Tap "New Exam" to create one.')),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: exams.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final exam = exams[i];
                return Card(
                  child: ListTile(
                    title: Text(exam.title),
                    subtitle: Text('${exam.totalQuestions} questions · ${_statusLabel(exam.status)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await context.push('/exams/${exam.id}');
                      _refresh();
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Draft – set up answer key';
      case 'ready':
        return 'Ready to start';
      case 'active':
        return 'Active';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }
}
