import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/session.dart';
import '../shared/ui.dart';

class ClassesPage extends ConsumerStatefulWidget {
  const ClassesPage({super.key});
  @override
  ConsumerState<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends ConsumerState<ClassesPage> {
  int revision = 0;
  @override
  Widget build(BuildContext context) {
    final session = ref.read(sessionProvider);
    final now = DateTime.now();
    final from = DateFormat('yyyy-MM-dd')
        .format(now.subtract(const Duration(days: 7)));
    final to = DateFormat('yyyy-MM-dd')
        .format(now.add(const Duration(days: 28)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(
          'Agenda',
          'Turmas e chamadas das próximas semanas.',
          action: session.manager
              ? FilledButton.icon(
                  onPressed: () => _newClass(session),
                  icon: const Icon(Icons.add),
                  label: const Text('Nova turma'),
                )
              : null,
        ),
        KeyedSubtree(
          key: ValueKey(revision),
          child: LoadView(
            load: () =>
                session.api.get('${session.base}/sessions?from=$from&to=$to'),
            builder: (data, reload) {
              final items = (data as List).cast<Map<String, dynamic>>();
              if (items.isEmpty) {
                return EmptyState(
                  'Nenhuma aula programada',
                  'Crie uma turma para gerar as próximas sessões.',
                  action: session.manager
                      ? FilledButton(
                          onPressed: () => _newClass(session),
                          child: const Text('Criar turma'),
                        )
                      : null,
                );
              }
              return Column(
                children: items.map((item) {
                  final date = DateTime.parse(item['startsAt'] as String)
                      .toLocal();
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(18),
                      leading: SizedBox(
                        width: 54,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('dd').format(date),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              DateFormat('MMM').format(date).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      title: Text(
                        item['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${DateFormat('dd/MM · HH:mm').format(date)} · ${item['present']} presentes',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusPill(item['status'] as String),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => context.go('/sessions/${item['id']}'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _newClass(Session session) async {
    final name = TextEditingController(text: 'Jiu-Jitsu · Todos os níveis');
    final time = TextEditingController(text: '19:00');
    int day = DateTime.now().weekday;
    bool busy = false;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Nova turma'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nome da turma'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: day,
                  decoration: const InputDecoration(labelText: 'Dia da semana'),
                  items:
                      const [
                            'Segunda',
                            'Terça',
                            'Quarta',
                            'Quinta',
                            'Sexta',
                            'Sábado',
                            'Domingo',
                          ]
                          .asMap()
                          .entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key + 1,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => day = value!,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: time,
                  decoration: const InputDecoration(
                    labelText: 'Horário (HH:mm)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setDialog(() => busy = true);
                      try {
                        await session.api.post(
                          '${session.base}/class-templates',
                          {
                            'name': name.text,
                            'weekday': day,
                            'time': time.text,
                            'durationMinutes': 60,
                          },
                        );
                        if (context.mounted) Navigator.pop(context);
                        setState(() => revision++);
                      } catch (e) {
                        if (context.mounted) showError(context, e);
                        setDialog(() => busy = false);
                      }
                    },
              child: const Text('Criar turma'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    time.dispose();
  }
}

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key, required this.id});
  final String id;
  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  final selected = <String>{};
  bool busy = false;
  int? version;
  String name = 'Chamada';

  @override
  Widget build(BuildContext context) {
    final session = ref.read(sessionProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(
          name,
          'Marque os presentes e revise antes de finalizar.',
          action: FilledButton.icon(
            onPressed: busy || version == null ? null : () => _submit(session),
            icon: const Icon(Icons.check),
            label: const Text('Finalizar chamada'),
          ),
        ),
        LoadView(
          load: () =>
              session.api.get('${session.base}/sessions/${widget.id}/roster'),
          builder: (data, reload) {
            final root = Map<String, dynamic>.from(data as Map);
            final classSession = Map<String, dynamic>.from(
              root['session'] as Map,
            );
            final students = (root['students'] as List)
                .cast<Map<String, dynamic>>();
            version = classSession['version'] as int;
            name = classSession['name'] as String;
            for (final student in students) {
              if (student['present'] == true) {
                selected.add(student['id'] as String);
              }
            }
            if (classSession['status'] == 'COMPLETED') {
              return EmptyState(
                'Chamada concluída',
                '${selected.length} presença(s) registradas.',
                icon: Icons.task_alt,
                action: OutlinedButton(
                  onPressed: () => context.go('/classes'),
                  child: const Text('Voltar para agenda'),
                ),
              );
            }
            return Column(
              children: [
                Row(
                  children: [
                    Text(
                      '${selected.length} de ${students.length} presentes',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() {
                        selected
                          ..clear()
                          ..addAll(students.map((e) => e['id'] as String));
                      }),
                      child: const Text('Marcar todos'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...students.map(
                  (student) => Card(
                    child: CheckboxListTile(
                      value: selected.contains(student['id']),
                      onChanged: (value) => setState(() {
                        value == true
                            ? selected.add(student['id'] as String)
                            : selected.remove(student['id']);
                      }),
                      title: Text(student['name'] as String),
                      subtitle: Text('Faixa ${student['belt']}'),
                      secondary: CircleAvatar(
                        child: Text(
                          (student['name'] as String).substring(0, 1),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _submit(Session session) async {
    if (!await confirmAction(
      context,
      'Finalizar chamada?',
      'Serão registradas ${selected.length} presenças.',
    )) {
      return;
    }
    setState(() => busy = true);
    try {
      await session.api.post(
        '${session.base}/sessions/${widget.id}/attendance/batch',
        {'studentIds': selected.toList(), 'version': version},
      );
      if (mounted) context.go('/classes');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
