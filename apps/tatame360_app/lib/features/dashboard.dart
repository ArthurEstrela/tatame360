import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/session.dart';
import '../shared/ui.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.read(sessionProvider);
    Future<dynamic> load() async {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      return Future.wait([
        session.api.get('${session.base}/analytics/overview'),
        session.api.get('${session.base}/sessions?from=$today&to=$today'),
        session.api.get('${session.base}/retention/attention'),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeading(
          'Hoje no Tatame',
          'Aulas, presença e alunos que precisam de atenção.',
        ),
        LoadView(
          load: load,
          builder: (data, reload) {
            final values = data as List;
            final overview = Map<String, dynamic>.from(values[0] as Map);
            final sessions = (values[1] as List).cast<Map<String, dynamic>>();
            final attention = (values[2] as List).cast<Map<String, dynamic>>();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _Metric(
                      'Alunos ativos',
                      '${overview['activeStudents']}',
                      Icons.people_outline,
                    ),
                    _Metric(
                      'Presenças em 7 dias',
                      '${overview['presencesWeek']}',
                      Icons.how_to_reg_outlined,
                    ),
                    _Metric(
                      'Em atenção',
                      '${overview['attention']}',
                      Icons.favorite_border,
                    ),
                    _Metric(
                      'Pausados',
                      '${overview['pausedStudents']}',
                      Icons.pause_circle_outline,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionTitle(
                  'Aulas de hoje',
                  action: TextButton(
                    onPressed: () => context.go('/classes'),
                    child: const Text('Ver agenda'),
                  ),
                ),
                if (sessions.isEmpty)
                  const EmptyState(
                    'Nenhuma aula hoje',
                    'Crie uma turma na Agenda para começar a registrar presença.',
                    icon: Icons.calendar_today_outlined,
                  )
                else
                  ...sessions.map((item) => _sessionCard(context, item)),
                const SizedBox(height: 28),
                _SectionTitle(
                  'Alunos em atenção',
                  action: TextButton(
                    onPressed: () => context.go('/attention'),
                    child: const Text('Ver todos'),
                  ),
                ),
                if (attention.isEmpty)
                  const EmptyState(
                    'Nenhum acompanhamento aberto',
                    'Quando houver histórico suficiente, quedas relevantes aparecerão aqui.',
                    icon: Icons.favorite_outline,
                  )
                else
                  ...attention
                      .take(3)
                      .map((item) => _attentionCard(context, item)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _sessionCard(BuildContext context, Map<String, dynamic> item) {
    final time = DateFormat('HH:mm')
        .format(DateTime.parse(item['startsAt'] as String).toLocal());
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: const CircleAvatar(child: Icon(Icons.sports_martial_arts)),
        title: Text(
          item['name'] as String,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(time),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusPill(item['status'] as String),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => context.go('/sessions/${item['id']}'),
      ),
    );
  }

  Widget _attentionCard(BuildContext context, Map<String, dynamic> item) =>
      Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(18),
          title: Text(
            item['name'] as String,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            item['reason'] as String,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: item['score'] == null
              ? const Text('Novo')
              : Text(
                  '${item['score']}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: green,
                  ),
                ),
          onTap: () => context.go('/attention'),
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 240,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2EA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: green),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                Text(label, style: const TextStyle(color: muted)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ),
        ?action,
      ],
    ),
  );
}
