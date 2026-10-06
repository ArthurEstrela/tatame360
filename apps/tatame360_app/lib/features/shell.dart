import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/session.dart';
import '../shared/ui.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;
  static const baseItems = [
    ('/', 'Hoje', Icons.space_dashboard_outlined),
    ('/students', 'Alunos', Icons.people_outline),
    ('/classes', 'Agenda', Icons.calendar_month_outlined),
    ('/attention', 'Acompanhamento', Icons.favorite_border),
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final wide = MediaQuery.sizeOf(context).width >= 1000;
        final items = [
          ...baseItems,
          if (session.manager)
            ('/settings/team', 'Equipe', Icons.manage_accounts_outlined),
        ];
        int selected = items.indexWhere(
          (i) => i.$1 == '/' ? path == '/' : path.startsWith(i.$1),
        );
        if (path.startsWith('/sessions')) selected = 2;
        if (selected < 0) selected = 0;
        Future<void> logout() async {
          try {
            await session.logout();
          } catch (e) {
            if (context.mounted) showError(context, e);
          }
        }

        final supported = [
          'OWNER',
          'MANAGER',
          'INSTRUCTOR',
          'FRONT_DESK',
        ].contains(session.academy?['role']);
        final content = supported
            ? KeyedSubtree(key: ValueKey(session.academy?['id']), child: child)
            : const EmptyState(
                'Acesso de aluno em preparação',
                'Esta primeira entrega está disponível para a equipe administrativa.',
              );
        return Scaffold(
          appBar: wide
              ? null
              : AppBar(
                  title: const Text(
                    'TATAME360',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Sair',
                      onPressed: logout,
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
          bottomNavigationBar: wide || !supported
              ? null
              : NavigationBar(
                  selectedIndex: selected,
                  onDestinationSelected: (i) => context.go(items[i].$1),
                  destinations: items
                      .map(
                        (i) => NavigationDestination(
                          icon: Icon(i.$3),
                          label: i.$2 == 'Acompanhamento' ? 'Atenção' : i.$2,
                        ),
                      )
                      .toList(),
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (wide)
                  Container(
                    width: 244,
                    color: ink,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'TATAME360',
                            style: TextStyle(
                              color: Colors.white,
                              letterSpacing: 2.5,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        const Padding(
                          padding: EdgeInsets.only(left: 12, bottom: 16),
                          child: Text(
                            'SUA ACADEMIA',
                            style: TextStyle(
                              color: Color(0xFF9FAFA5),
                              fontSize: 11,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        if (supported)
                          for (int i = 0; i < items.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                tileColor: selected == i
                                    ? const Color(0xFF30483A)
                                    : Colors.transparent,
                                leading: Icon(
                                  items[i].$3,
                                  color: selected == i
                                      ? const Color(0xFFBFE1B7)
                                      : const Color(0xFFBAC9BF),
                                ),
                                title: Text(
                                  items[i].$2,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                onTap: () => context.go(items[i].$1),
                              ),
                            ),
                        const Spacer(),
                        Text(
                          session.user?['name'] as String? ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: logout,
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Sair da conta'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFBAC9BF),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: wide ? 36 : 20,
                          vertical: 18,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE0E4DC)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                session.academy?['name'] as String? ??
                                    'Selecione uma academia',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: ink,
                                ),
                              ),
                            ),
                            if (session.academies.length > 1)
                              PopupMenuButton<String>(
                                tooltip: 'Trocar academia',
                                onSelected: (id) {
                                  session.selectAcademy(id);
                                  context.go('/');
                                },
                                itemBuilder: (_) => session.academies
                                    .map(
                                      (a) => PopupMenuItem(
                                        value: a['id'] as String,
                                        child: Text(a['name'] as String),
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(wide ? 36 : 20),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1400),
                              child: content,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
