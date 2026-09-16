import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/sign_in_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/exams/answer_key_review_screen.dart';
import '../features/exams/exam_create_screen.dart';
import '../features/exams/exam_detail_screen.dart';
import '../features/exams/exam_list_screen.dart';
import '../features/exams/exam_model.dart';
import '../features/submissions/capture_submission_screen.dart';
import '../features/submissions/submission_review_screen.dart';
import 'supabase_client.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
  redirect: (context, state) {
    final loggedIn = supabase.auth.currentSession != null;
    final onAuthScreen = state.matchedLocation == '/' || state.matchedLocation == '/sign-up';
    if (!loggedIn) return onAuthScreen ? null : '/';
    if (loggedIn && onAuthScreen) return '/exams';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SignInScreen()),
    GoRoute(path: '/sign-up', builder: (context, state) => const SignUpScreen()),
    GoRoute(path: '/exams', builder: (context, state) => const ExamListScreen()),
    GoRoute(path: '/exams/new', builder: (context, state) => const ExamCreateScreen()),
    GoRoute(
      path: '/exams/:id',
      builder: (context, state) => ExamDetailScreen(examId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/exams/:id/answer-key',
      builder: (context, state) => AnswerKeyReviewScreen(
        examId: state.pathParameters['id']!,
        detectedAnswers: (state.extra as Map<String, String>?) ?? const {},
      ),
    ),
    GoRoute(
      path: '/exams/:id/submissions/new',
      builder: (context, state) => CaptureSubmissionScreen(exam: state.extra as Exam),
    ),
    GoRoute(
      path: '/exams/:id/submissions/review',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return SubmissionReviewScreen(
          exam: data['exam'] as Exam,
          photo: data['photo'] as File,
          studentName: data['studentName'] as String,
          rollNumber: data['rollNumber'] as String?,
          detectedAnswers: data['detectedAnswers'] as Map<String, String>,
        );
      },
    ),
  ],
);
