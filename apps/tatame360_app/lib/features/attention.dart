import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/session.dart';
import '../shared/ui.dart';

class AttentionPage extends ConsumerStatefulWidget {
  const AttentionPage({super.key});
  @override
  ConsumerState<AttentionPage> createState() => _AttentionPageState();
}

class _AttentionPageState extends ConsumerState<AttentionPage> {
  int revision = 0;
  bool evaluating = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.read(sessionProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(
          'Acompanhamento',
          'Quedas de frequência transformadas em ações humanas.',
          action: session.manager
              ? OutlinedButton.icon(
                  onPressed: evaluating ? null : () => evaluate(session),
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    evaluating ? 'Analisando...' : 'Atualizar análise',
                  ),
                )
              : null,
        ),
        KeyedSubtree(
          key: ValueKey(revision),
          child: LoadView(
            load: () => session.api.get('${session.base}/retention/attention'),
            builder: (data, reload) {
              final items = (data as List).cast<Map<String, dynamic>>();
              if (items.isEmpty) {
                return const EmptyState(
                  'Nenhum acompanhamento aberto',
                  'Quando houver histórico confiável e uma queda relevante, ela aparecerá aqui.',
                  icon: Icons.favorite_outline,
                );
              }
              return Column(
                children: items.map((item) => _card(item, session)).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _card(Map<String, dynamic> item, Session session) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item['name'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              StatusPill(item['status'] as String),
              if (item['score'] != null) ...[
                const SizedBox(width: 12),
                Text(
                  '${item['score']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: green,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item['reason'] as String,
            style: const TextStyle(color: muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => contact(item, session),
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Registrar contato'),
              ),
              OutlinedButton(
                onPressed: () => close(item, session),
                child: const Text('Encerrar acompanhamento'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> evaluate(Session session) async {
    setState(() => evaluating = true);
    try {
      await session.api.post('${session.base}/retention/evaluate', {});
      setState(() => revision++);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => evaluating = false);
    }
  }

  Future<void> contact(Map<String, dynamic> item, Session session) async {
    String outcome = 'Conversou';
    final note = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text('Contato com ${item['name']}'),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: outcome,
                  decoration: const InputDecoration(labelText: 'Resultado'),
                  items:
                      [
                            'Sem resposta',
                            'Conversou',
                            'Dificuldade de horário',
                            'Pretende voltar',
                            'Pediu pausa',
                            'Pediu cancelamento',
                            'Outro',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => outcome = value!,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: note,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Observação'),
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
                    '${session.base}/crm/tasks/${item['id']}/contacts',
                    {
                      'outcome': outcome,
                      'note': note.text,
                      'version': item['version'],
                    },
                  );
                  if (context.mounted) Navigator.pop(context);
                  setState(() => revision++);
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
              child: const Text('Salvar contato'),
            ),
          ],
        ),
      ),
    );
    note.dispose();
  }

  Future<void> close(Map<String, dynamic> item, Session session) async {
    if (!await confirmAction(
      context,
      'Encerrar acompanhamento?',
      'O histórico será preservado.',
    )) {
      return;
    }
    try {
      await session.api.post(
        '${session.base}/crm/tasks/${item['id']}/complete',
        {'reason': 'Encerrado pela equipe', 'version': item['version']},
      );
      setState(() => revision++);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }
}
