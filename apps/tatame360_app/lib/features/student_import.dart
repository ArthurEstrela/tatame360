import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../shared/ui.dart';

class StudentImportPage extends ConsumerStatefulWidget {
  const StudentImportPage({super.key});

  @override
  ConsumerState<StudentImportPage> createState() => _StudentImportPageState();
}

class _StudentImportPageState extends ConsumerState<StudentImportPage> {
  Map<String, dynamic>? preview;
  String? selectedClass, fileName, error;
  int? imported;
  bool busy = false, acceptDuplicates = false;

  Future<void> pickFile() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (picked.isEmpty) return;
    final file = picked.single;
    final bytes = await file.readAsBytes();
    setState(() {
      busy = true;
      error = null;
      preview = null;
      imported = null;
      acceptDuplicates = false;
      fileName = file.name;
    });
    try {
      final session = ref.read(sessionProvider);
      final result = await session.api.uploadCsv(
        '${session.base}/imports/preview',
        bytes,
        file.name,
      );
      setState(() => preview = Map<String, dynamic>.from(result as Map));
    } catch (e) {
      setState(() => error = Api.message(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> confirm() async {
    if (preview == null || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final session = ref.read(sessionProvider);
      final result = Map<String, dynamic>.from(
        await session.api.post(
          '${session.base}/imports/${preview!['id']}/confirm',
          {
            'acceptPossibleDuplicates': acceptDuplicates,
            'classId': selectedClass,
          },
        ) as Map,
      );
      setState(() {
        imported = result['imported'] as int;
        preview = null;
      });
    } catch (e) {
      setState(() => error = Api.message(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> saveTemplate() async {
    final content =
        '\uFEFFnome,data_inicio,email,telefone\nAna Exemplo,2026-01-15,ana@example.com,11999999999\n';
    try {
      await FilePicker.saveFile(
        fileName: 'modelo_alunos_tatame360.csv',
        bytes: Uint8List.fromList(utf8.encode(content)),
        mimeType: 'text/csv;charset=utf-8',
      );
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(sessionProvider);
    if (!session.manager) {
      return const EmptyState(
        'Acesso restrito',
        'A importação está disponível para owners e gestores.',
        icon: Icons.lock_outline,
      );
    }
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
        PageHeading(
          'Importar alunos',
          'Envie um CSV, revise cada linha e só então confirme o cadastro.',
          action: OutlinedButton.icon(
            onPressed: saveTemplate,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Baixar modelo'),
          ),
        ),
        _Instructions(onPick: busy ? null : pickFile, fileName: fileName),
        if (busy) ...[
          const SizedBox(height: 24),
          const LinearProgressIndicator(),
        ],
        if (error != null) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(error!),
          ),
        ],
        if (imported != null) ...[
          const SizedBox(height: 24),
          EmptyState(
            'Importação concluída',
            '$imported aluno(s) foram cadastrados com sucesso.',
            icon: Icons.check_circle_outline,
            action: FilledButton(
              onPressed: () => context.go('/students'),
              child: const Text('Ver alunos'),
            ),
          ),
        ],
        if (preview != null) ...[
          const SizedBox(height: 28),
          _Preview(
            preview: preview!,
            acceptDuplicates: acceptDuplicates,
            selectedClass: selectedClass,
            onAcceptDuplicates: (value) =>
                setState(() => acceptDuplicates = value),
            onClass: (value) => setState(() => selectedClass = value),
            classes: () => session.api.get('${session.base}/class-templates'),
            onConfirm: busy ? null : confirm,
          ),
        ],
      ],
    );
  }
}

class _Instructions extends StatelessWidget {
  const _Instructions({required this.onPick, required this.fileName});
  final VoidCallback? onPick;
  final String? fileName;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Formato esperado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Colunas obrigatórias: nome e data_inicio (AAAA-MM-DD). E-mail e telefone são opcionais. Aceita vírgula ou ponto e vírgula, até 5 MB e 5.000 linhas.',
                style: TextStyle(color: muted, height: 1.5),
              ),
              if (fileName != null) ...[
                const SizedBox(height: 12),
                Text(
                  fileName!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          );
          final button = FilledButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(fileName == null ? 'Selecionar CSV' : 'Trocar arquivo'),
          );
          if (constraints.maxWidth < 650) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [details, const SizedBox(height: 20), button],
            );
          }
          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 24),
              button,
            ],
          );
        },
      ),
    ),
  );
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.preview,
    required this.acceptDuplicates,
    required this.selectedClass,
    required this.onAcceptDuplicates,
    required this.onClass,
    required this.classes,
    required this.onConfirm,
  });
  final Map<String, dynamic> preview;
  final bool acceptDuplicates;
  final String? selectedClass;
  final ValueChanged<bool> onAcceptDuplicates;
  final ValueChanged<String?> onClass;
  final Future<dynamic> Function() classes;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final rows = (preview['rows'] as List).cast<Map<String, dynamic>>();
    final invalid = rows.where((r) => (r['errors'] as List).isNotEmpty).length;
    final duplicates = rows.where((r) => r['possibleDuplicate'] == true).length;
    final canConfirm = invalid == 0 && (duplicates == 0 || acceptDuplicates);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Count(label: 'Linhas', value: rows.length, color: green),
            _Count(
              label: 'Válidas',
              value: rows.length - invalid,
              color: green,
            ),
            _Count(
              label: 'Com erros',
              value: invalid,
              color: invalid > 0 ? Colors.red.shade700 : green,
            ),
            _Count(
              label: 'Possíveis duplicatas',
              value: duplicates,
              color: duplicates > 0 ? Colors.orange.shade800 : green,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Configuração da importação',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                LoadView(
                  load: classes,
                  builder: (data, _) {
                    final items = (data as List).cast<Map<String, dynamic>>();
                    return DropdownButtonFormField<String?>(
                      initialValue: selectedClass,
                      decoration: const InputDecoration(
                        labelText: 'Turma principal (opcional)',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sem turma principal'),
                        ),
                        ...items.map(
                          (item) => DropdownMenuItem<String?>(
                            value: item['id'] as String,
                            child: Text(item['name'] as String),
                          ),
                        ),
                      ],
                      onChanged: onClass,
                    );
                  },
                ),
                if (duplicates > 0) ...[
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: acceptDuplicates,
                    onChanged: (value) => onAcceptDuplicates(value ?? false),
                    title: const Text('Revisei as possíveis duplicatas'),
                    subtitle: const Text(
                      'Os registros serão criados como pessoas distintas.',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Linha')),
                  DataColumn(label: Text('Nome')),
                  DataColumn(label: Text('Data de início')),
                  DataColumn(label: Text('Contato')),
                  DataColumn(label: Text('Resultado')),
                ],
                rows: rows.take(100).map((row) {
                  final errors = (row['errors'] as List).cast<String>();
                  final duplicate = row['possibleDuplicate'] == true;
                  final result = errors.isNotEmpty
                      ? errors.join(' ')
                      : duplicate
                      ? 'Possível duplicata'
                      : 'Válida';
                  return DataRow(
                    cells: [
                      DataCell(Text('${row['line']}')),
                      DataCell(Text(row['name'] as String)),
                      DataCell(Text(row['startsOn'] as String)),
                      DataCell(
                        Text(
                          (row['email'] as String).isNotEmpty
                              ? row['email'] as String
                              : (row['phone'] as String).isNotEmpty
                              ? row['phone'] as String
                              : '—',
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 260,
                          child: Text(
                            result,
                            style: TextStyle(
                              color: errors.isNotEmpty
                                  ? Colors.red.shade700
                                  : duplicate
                                  ? Colors.orange.shade800
                                  : green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        if (rows.length > 100)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Exibindo as primeiras 100 de ${rows.length} linhas.',
              style: const TextStyle(color: muted),
            ),
          ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: canConfirm ? onConfirm : null,
            icon: const Icon(Icons.check),
            label: Text(
              invalid > 0
                  ? 'Corrija o arquivo para continuar'
                  : 'Importar alunos',
            ),
          ),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 180,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE1E6DF)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
