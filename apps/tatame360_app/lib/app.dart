import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/session.dart';
import 'features/attention.dart';
import 'features/account_access.dart';
import 'features/classes.dart';
import 'features/dashboard.dart';
import 'features/login.dart';
import 'features/shell.dart';
import 'features/student_import.dart';
import 'features/students.dart';
import 'features/team.dart';
import 'shared/ui.dart';

class TatameApp extends ConsumerStatefulWidget {
  const TatameApp({super.key});
  @override
  ConsumerState<TatameApp> createState() => _TatameAppState();
}

class _TatameAppState extends ConsumerState<TatameApp> {
  late final GoRouter router;
  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionProvider);
    router = GoRouter(
      initialLocation: '/',
      refreshListenable: session,
      redirect: (_, state) {
        final public = {
          '/login',
          '/forgot-password',
          '/reset-password',
          '/invite',
        }.contains(state.matchedLocation);
        if (session.loading) {
          if (public) return null;
          return state.matchedLocation == '/loading' ? null : '/loading';
        }
        if (public) return null;
        if (!session.authenticated) {
          return '/login';
        }
        if (state.matchedLocation == '/login' ||
            state.matchedLocation == '/loading') {
          return '/';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/loading',
          builder: (_, _) =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (_, state) => ResetPasswordPage(
            token: state.uri.queryParameters['token'] ?? '',
          ),
        ),
        GoRoute(
          path: '/invite',
          builder: (_, state) =>
              InvitationPage(token: state.uri.queryParameters['token'] ?? ''),
        ),
        ShellRoute(
          builder: (_, state, child) =>
              AppShell(path: state.uri.path, child: child),
          routes: [
            GoRoute(path: '/', builder: (_, _) => const DashboardPage()),
            GoRoute(path: '/students', builder: (_, _) => const StudentsPage()),
            GoRoute(
              path: '/students/import',
              builder: (_, _) => const StudentImportPage(),
            ),
            GoRoute(
              path: '/students/:id',
              builder: (_, state) =>
                  StudentPage(id: state.pathParameters['id']!),
            ),
            GoRoute(path: '/classes', builder: (_, _) => const ClassesPage()),
            GoRoute(
              path: '/sessions/:id',
              builder: (_, state) =>
                  AttendancePage(id: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/attention',
              builder: (_, _) => const AttentionPage(),
            ),
            GoRoute(
              path: '/settings/team',
              builder: (_, _) => const TeamPage(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, _) => Scaffold(
        body: Center(
          child: EmptyState(
            'Página não encontrada',
            'Volte para o início.',
            action: FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Ir para Hoje'),
            ),
          ),
        ),
      ),
    );
    session.initialize();
  }

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Tatame360',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    routerConfig: router,
  );
}
