import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../shared/ui.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final email = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false;
  String? message, resetToken, error;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = Map<String, dynamic>.from(
        await ref.read(sessionProvider).api.post('/auth/password/forgot', {
          'email': email.text.trim(),
        }) as Map,
      );
      setState(() {
        message = result['message'] as String;
        resetToken = result['resetToken'] as String?;
      });
    } catch (e) {
      setState(() => error = Api.message(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AccessFrame(
    title: 'Recuperar acesso',
    subtitle: 'Informe o e-mail usado na sua conta.',
    child: message != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Notice(message!),
              if (resetToken != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'O ambiente local está exibindo o link de teste. Em produção, ele será enviado pelo canal de e-mail configurado.',
                  style: TextStyle(color: muted, height: 1.5),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(
                    '/reset-password?token=${Uri.encodeQueryComponent(resetToken!)}',
                  ),
                  child: const Text('Redefinir senha agora'),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Voltar para o login'),
              ),
            ],
          )
        : Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: email,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Informe um e-mail válido.'
                      : null,
                ),
                if (error != null) ...[
                  const SizedBox(height: 14),
                  Text(error!, style: _errorStyle(context)),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const _ButtonProgress()
                      : const Text('Enviar instruções'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: busy ? null : () => context.go('/login'),
                  child: const Text('Voltar para o login'),
                ),
              ],
            ),
          ),
  );
}

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, required this.token});
  final String token;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final password = TextEditingController();
  final confirmation = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false, done = false, visible = false;
  String? error;

  @override
  void dispose() {
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(sessionProvider).api.post('/auth/password/reset', {
        'token': widget.token,
        'password': password.text,
      });
      setState(() => done = true);
    } catch (e) {
      setState(() => error = Api.message(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AccessFrame(
    title: 'Criar nova senha',
    subtitle: 'A nova senha encerra as sessões abertas da conta.',
    child: widget.token.isEmpty
        ? const _InvalidLink(kind: 'redefinição de senha')
        : done
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Notice('Senha alterada com sucesso.'),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Entrar com a nova senha'),
              ),
            ],
          )
        : Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: password,
                  obscureText: !visible,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Nova senha',
                    helperText: 'Use pelo menos 12 caracteres.',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => visible = !visible),
                      icon: Icon(
                        visible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => (value?.length ?? 0) < 12
                      ? 'A senha deve ter pelo menos 12 caracteres.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmation,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar nova senha',
                  ),
                  validator: (value) =>
                      value != password.text ? 'As senhas não conferem.' : null,
                ),
                if (error != null) ...[
                  const SizedBox(height: 14),
                  Text(error!, style: _errorStyle(context)),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const _ButtonProgress()
                      : const Text('Salvar nova senha'),
                ),
              ],
            ),
          ),
  );
}

class InvitationPage extends ConsumerWidget {
  const InvitationPage({super.key, required this.token});
  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _AccessFrame(
    title: 'Convite para a equipe',
    subtitle: 'Confirme seu acesso à academia.',
    child: token.isEmpty
        ? const _InvalidLink(kind: 'convite')
        : LoadView(
            load: () => ref
                .read(sessionProvider)
                .api
                .get('/auth/invitations/${Uri.encodeComponent(token)}'),
            builder: (data, _) => _InvitationForm(
              token: token,
              invitation: Map<String, dynamic>.from(data as Map),
            ),
          ),
  );
}

class _InvitationForm extends ConsumerStatefulWidget {
  const _InvitationForm({required this.token, required this.invitation});
  final String token;
  final Map<String, dynamic> invitation;

  @override
  ConsumerState<_InvitationForm> createState() => _InvitationFormState();
}

class _InvitationFormState extends ConsumerState<_InvitationForm> {
  late final TextEditingController name = TextEditingController(
    text: widget.invitation['name'] as String? ?? '',
  );
  final password = TextEditingController();
  final confirmation = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false, done = false, visible = false;
  String? error;

  bool get existing => widget.invitation['existingAccount'] == true;

  @override
  void dispose() {
    name.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(sessionProvider).api.post(
        '/auth/invitations/${Uri.encodeComponent(widget.token)}/accept',
        {'name': name.text.trim(), 'password': password.text},
      );
      setState(() => done = true);
    } catch (e) {
      setState(() => error = Api.message(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Notice(
            'Convite aceito. Você agora faz parte de ${widget.invitation['academyName']}.',
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('Entrar no Tatame360'),
          ),
        ],
      );
    }
    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.invitation['academyName'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.invitation['email']} · ${_roleLabel(widget.invitation['role'] as String)}',
                    style: const TextStyle(color: muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (!existing) ...[
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Seu nome'),
              validator: (value) =>
                  (value?.trim().length ?? 0) < 2 ? 'Informe seu nome.' : null,
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: password,
            obscureText: !visible,
            decoration: InputDecoration(
              labelText: existing ? 'Senha atual da conta' : 'Crie uma senha',
              helperText: existing ? null : 'Use pelo menos 12 caracteres.',
              suffixIcon: IconButton(
                onPressed: () => setState(() => visible = !visible),
                icon: Icon(
                  visible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            validator: (value) => (value?.length ?? 0) < 12
                ? 'A senha deve ter pelo menos 12 caracteres.'
                : null,
          ),
          if (!existing) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: confirmation,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar senha'),
              validator: (value) =>
                  value != password.text ? 'As senhas não conferem.' : null,
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 14),
            Text(error!, style: _errorStyle(context)),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: busy ? null : submit,
            child: busy
                ? const _ButtonProgress()
                : const Text('Aceitar convite'),
          ),
        ],
      ),
    );
  }
}

class _AccessFrame extends StatelessWidget {
  const _AccessFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title, subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'TATAME360',
                  style: TextStyle(
                    color: green,
                    fontSize: 20,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 34),
                Text(
                  title,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(subtitle, style: const TextStyle(color: muted)),
                const SizedBox(height: 28),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF2EA),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, color: green),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: const TextStyle(height: 1.5))),
      ],
    ),
  );
}

class _InvalidLink extends StatelessWidget {
  const _InvalidLink({required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context) => EmptyState(
    'Link inválido',
    'Solicite um novo link de $kind.',
    icon: Icons.link_off_outlined,
    action: TextButton(
      onPressed: () => context.go('/login'),
      child: const Text('Voltar para o login'),
    ),
  );
}

class _ButtonProgress extends StatelessWidget {
  const _ButtonProgress();
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}

TextStyle _errorStyle(BuildContext context) =>
    TextStyle(color: Theme.of(context).colorScheme.error);

String _roleLabel(String role) =>
    {
      'OWNER': 'Proprietário',
      'MANAGER': 'Gestor',
      'INSTRUCTOR': 'Professor',
      'FRONT_DESK': 'Recepção',
    }[role] ??
    role;
