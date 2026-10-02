import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/session.dart';
import 'features/attention.dart';
import 'features/classes.dart';
import 'features/dashboard.dart';
import 'features/login.dart';
import 'features/shell.dart';
import 'features/students.dart';
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
        if (session.loading) {
          return state.matchedLocation == '/loading' ? null : '/loading';
        }
        if (!session.authenticated) {
          return state.matchedLocation == '/login' ? null : '/login';
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
        ShellRoute(
          builder: (_, state, child) =>
              AppShell(path: state.uri.path, child: child),
          routes: [
            GoRoute(path: '/', builder: (_, _) => const DashboardPage()),
            GoRoute(path: '/students', builder: (_, _) => const StudentsPage()),
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
