import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;

import 'core/theme/app_theme.dart';
import 'core/api/api_client.dart';
import 'shared/providers/auth_provider.dart';

import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/dashboard/teacher_dashboard.dart';
import 'features/dashboard/student_dashboard.dart';
import 'features/classroom/classroom_detail_screen.dart';
import 'features/classroom/meet_prep_screen.dart';
import 'features/assessment/create/create_assessment_screen.dart';
import 'features/assessment/consent/consent_modal.dart';
import 'features/assessment/take/take_assessment_screen.dart';
import 'features/assessment/results/student_result_screen.dart';
import 'features/assessment/results/proctoring_report_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/classroom/meeting_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      center: true,
      title: 'Examify',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ExamifyApp(),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isAuthRoute =
          state.uri.path == '/' || state.uri.path == '/register';

      if (!isAuth && !isAuthRoute) return '/';

      if (isAuth && isAuthRoute) {
        final role = authState.user?.role.name;
        return role == 'teacher' ? '/teacher' : '/student';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboard(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: '/classroom/:id',
        builder: (context, state) =>
            ClassroomDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/classroom/:id/meet-prep',
        builder: (context, state) =>
            MeetPrepScreen(classroomId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/classroom/:id/meet',
        builder: (context, state) =>
            MeetPrepScreen(classroomId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/meeting/:channel',
        builder: (context, state) {
          final classroomId = state.uri.queryParameters['classroomId'];
          return MeetingScreen(
            channelName: state.pathParameters['channel']!,
            classroomId: classroomId,
          );
        },
      ),
      GoRoute(
        path: '/classroom/:id/create-assessment',
        builder: (context, state) =>
            CreateAssessmentScreen(classroomId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/assessment/:id/consent',
        builder: (context, state) =>
            ConsentModal(assessmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/assessment/:id/take',
        builder: (context, state) => TakeAssessmentScreen(
          assessmentId: state.pathParameters['id']!,
          attemptId:
              int.tryParse(state.uri.queryParameters['attemptId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/assessment/:id/result',
        builder: (context, state) => StudentResultScreen(
          assessmentId: state.pathParameters['id']!,
          result: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/assessment/:id/reports',
        builder: (context, state) =>
            ProctoringReportScreen(assessmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});

class ExamifyApp extends ConsumerWidget {
  const ExamifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Examify',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
