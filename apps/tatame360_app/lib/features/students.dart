import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/session.dart';
import '../shared/ui.dart';

class StudentsPage extends ConsumerStatefulWidget {
  const StudentsPage({super.key});
  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage> {
  final search = TextEditingController();
  int revision = 0;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(sessionProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(
          'Alunos',
          'Cadastros, vínculos e histórico da academia.',
          action: session.manager
              ? FilledButton.icon(
                  onPressed: () async {
                    await _newStudent(context, session);
                    setState(() => revision++);
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Novo aluno'),
                )
              : null,
        ),
        TextField(
          controller: search,
          onSubmitted: (_) => setState(() => revision++),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Buscar por nome',
            suffixIcon: IconButton(
              tooltip: 'Buscar',
              onPressed: () => setState(() => revision++),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
        const SizedBox(height: 20),
        KeyedSubtree(
          key: ValueKey(revision),
          child: LoadView(
            load: () => session.api.get(
              '${session.base}/students?search=${Uri.encodeQueryComponent(search.text)}',
            ),
            builder: (data, reload) {
              final items = ((data as Map)['items'] as List)
                  .cast<Map<String, dynamic>>();
              if (items.isEmpty) {
                return const EmptyState(
                  'Nenhum aluno encontrado',
                  'Cadastre um aluno ou altere sua busca.',
                  icon: Icons.people_outline,
                );
              }
              return Column(
                children: items
                    .map(
                      (student) => Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            child: Text(
                              (student['name'] as String).substring(0, 1),
                            ),
                          ),
                          title: Text(
                            student['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Faixa ${student['belt']} · ${student['degrees']} grau(s)',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusPill(student['status'] as String),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () => context.go('/students/${student['id']}'),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _newStudent(BuildContext context, Session session) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    bool busy = false;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Novo aluno'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nome *'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(
                    labelText: 'E-mail (opcional)',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone (opcional)',
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
                      if (name.text.trim().isEmpty) return;
                      setDialog(() => busy = true);
                      try {
                        await session.api.post('${session.base}/students', {
                          'name': name.text,
                          'email': email.text.isEmpty ? null : email.text,
                          'phone': phone.text.isEmpty ? null : phone.text,
                          'startsOn': DateFormat('yyyy-MM-dd')
                              .format(DateTime.now()),
                          'classId': null,
                        });
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) showError(context, e);
                        setDialog(() => busy = false);
                      }
                    },
              child: const Text('Cadastrar'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    email.dispose();
    phone.dispose();
  }
}

class StudentPage extends ConsumerStatefulWidget {
  const StudentPage({super.key, required this.id});
  final String id;
  @override
  ConsumerState<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends ConsumerState<StudentPage> {
  int revision = 0;
  @override
  Widget build(BuildContext context) {
    final session = ref.read(sessionProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          onPressed: () => context.go('/students'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Voltar para alunos'),
          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: ValueKey(revision),
          child: LoadView(
            load: () =>
                session.api.get('${session.base}/students/${widget.id}'),
            builder: (data, reload) =>
                _details(Map<String, dynamic>.from(data as Map), session),
          ),
        ),
      ],
    );
  }

  Widget _details(Map<String, dynamic> student, Session session) {
    final presences = (student['presences'] as List)
        .cast<Map<String, dynamic>>();
    final promotions = (student['promotions'] as List)
        .cast<Map<String, dynamic>>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(
          student['name'] as String,
          'Faixa ${student['belt']} · ${student['degrees']} grau(s)',
          action: StatusPill(student['status'] as String),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _Info('Início', student['startsOn'].toString()),
            _Info('Presenças recentes', '${presences.length}'),
            _Info(
              'Contato',
              student['phone']?.toString().isNotEmpty == true
                  ? student['phone'].toString()
                  : 'Não informado',
            ),
          ],
        ),
        const SizedBox(height: 28),
        if (session.manager)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: student['status'] == 'ACTIVE'
                    ? () => _pause(student, session)
                    : null,
                icon: const Icon(Icons.pause),
                label: const Text('Registrar pausa'),
              ),
              OutlinedButton.icon(
                onPressed: student['status'] == 'CANCELLED'
                    ? null
                    : () => _cancel(student, session),
                icon: const Icon(Icons.person_off_outlined),
                label: const Text('Cancelar vínculo'),
              ),
              if (session.owner)
                FilledButton.icon(
                  onPressed: () => _promote(student, session),
                  icon: const Icon(Icons.military_tech_outlined),
                  label: const Text('Registrar graduação'),
                ),
            ],
          ),
        const SizedBox(height: 28),
        const Text(
          'Presenças recentes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (presences.isEmpty)
          const EmptyState(
            'Sem presenças',
            'As chamadas concluídas aparecerão aqui.',
          )
        else
          ...presences
              .take(10)
              .map(
                (p) => Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.check_circle_outline,
                      color: green,
                    ),
                    title: Text(p['name'] as String),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy · HH:mm').format(
                        DateTime.parse(p['startsAt'] as String).toLocal(),
                      ),
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 24),
        const Text(
          'Histórico de graduação',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (promotions.isEmpty)
          const EmptyState(
            'Sem eventos de graduação',
            'A faixa atual pode ter vindo do cadastro inicial.',
          )
        else
          ...promotions.map(
            (p) => Card(
              child: ListTile(
                leading: const Icon(Icons.military_tech_outlined),
                title: Text('Faixa ${p['belt']} · ${p['degrees']} grau(s)'),
                subtitle: Text(p['effectiveOn'].toString()),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pause(Map<String, dynamic> student, Session session) async {
    final end = DateTime.now().add(const Duration(days: 30));
    if (!await confirmAction(
      context,
      'Pausar por 30 dias?',
      'Alertas de retenção serão suspensos durante o período.',
    )) {
      return;
    }
    try {
      await session.api.post('${session.base}/students/${widget.id}/pause', {
        'endsOn': DateFormat('yyyy-MM-dd').format(end),
        'reason': 'Motivo pessoal',
      });
      setState(() => revision++);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _cancel(Map<String, dynamic> student, Session session) async {
    if (!await confirmAction(
      context,
      'Cancelar vínculo?',
      'O histórico do aluno será preservado.',
    )) {
      return;
    }
    try {
      await session.api.post(
        '${session.base}/students/${widget.id}/cancel',
        {},
      );
      setState(() => revision++);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _promote(Map<String, dynamic> student, Session session) async {
    const belts = ['Branca', 'Azul', 'Roxa', 'Marrom', 'Preta'];
    String belt = student['belt'] as String;
    int degrees = student['degrees'] as int;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text('Graduar ${student['name']}'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: belt,
                  decoration: const InputDecoration(labelText: 'Faixa'),
                  items: belts
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (value) => belt = value!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: degrees,
                  decoration: const InputDecoration(labelText: 'Graus'),
                  items: List.generate(
                    5,
                    (i) => DropdownMenuItem(value: i, child: Text('$i')),
                  ),
                  onChanged: (value) => degrees = value!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await session.api.post(
                    '${session.base}/students/${widget.id}/promotions',
                    {
                      'belt': belt,
                      'degrees': degrees,
                      'effectiveOn': DateFormat('yyyy-MM-dd')
                          .format(DateTime.now()),
                      'version': student['version'],
                    },
                  );
                  if (context.mounted) Navigator.pop(context);
                  setState(() => revision++);
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
              child: const Text('Confirmar graduação'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 250,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: muted)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
