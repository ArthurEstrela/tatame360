import 'package:flutter/material.dart';

import '../core/api.dart';

const ink = Color(0xFF192923),
    green = Color(0xFF236347),
    canvas = Color(0xFFF5F5F0),
    muted = Color(0xFF66736C);
ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: green, surface: Colors.white),
  scaffoldBackgroundColor: canvas,
  appBarTheme: const AppBarTheme(
    backgroundColor: canvas,
    foregroundColor: ink,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFCDD5CF)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE1E6DF)),
    ),
  ),
);

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key, this.action});
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: LayoutBuilder(
      builder: (context, c) {
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: ink,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: muted, height: 1.5)),
          ],
        );
        if (c.maxWidth < 650) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text,
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: text),
            if (action != null) ...[const SizedBox(width: 20), action!],
          ],
        );
      },
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.title,
    this.description, {
    super.key,
    this.action,
    this.icon = Icons.inbox_outlined,
  });
  final String title, description;
  final Widget? action;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: green),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    ),
  );
}

class LoadView extends StatefulWidget {
  const LoadView({super.key, required this.load, required this.builder});
  final Future<dynamic> Function() load;
  final Widget Function(dynamic data, VoidCallback reload) builder;
  @override
  State<LoadView> createState() => _LoadViewState();
}

class _LoadViewState extends State<LoadView> {
  late Future<dynamic> future;
  @override
  void initState() {
    super.initState();
    future = widget.load();
  }

  void reload() => setState(() {
    future = widget.load();
  });
  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
    future: future,
    builder: (context, s) {
      if (s.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(64),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (s.hasError) {
        return EmptyState(
          'Não foi possível carregar',
          Api.message(s.error!),
          action: FilledButton.icon(
            onPressed: reload,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        );
      }
      return widget.builder(s.data, reload);
    },
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final label =
        {
          'ACTIVE': 'Ativo',
          'PAUSED': 'Pausado',
          'CANCELLED': 'Cancelado',
          'COMPLETED': 'Chamada concluída',
          'SCHEDULED': 'Programada',
          'OPEN': 'Em atenção',
          'IN_PROGRESS': 'Em acompanhamento',
          'RETURN_OBSERVED': 'Retorno observado',
          'SNOOZED': 'Adiado',
        }[status] ??
        status;
    final attention = ['OPEN', 'PAUSED'].contains(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: attention ? const Color(0xFFFFF0D6) : const Color(0xFFEAF2EA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: attention ? const Color(0xFF825611) : green,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(Api.message(error))));
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ??
    false;
