import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../shared/ui.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false;
  bool visible = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(sessionProvider).login(email.text, password.text);
    } catch (e) {
      if (mounted) setState(() => error = Api.message(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketing = Container(
      color: ink,
      padding: const EdgeInsets.all(64),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_martial_arts, color: Color(0xFFB4DAB4), size: 64),
          SizedBox(height: 40),
          Text(
            'Mais presença.\nMais história\nno tatame.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 54,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 28),
          Text(
            'Gestão para a academia.\nCuidado com a jornada de cada aluno.',
            style: TextStyle(
              color: Color(0xFFC2D0C6),
              fontSize: 18,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
    final login = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: form,
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
                const SizedBox(height: 40),
                const Text(
                  'Bem-vindo ao tatame.',
                  style: TextStyle(
                    fontSize: 30,
                    color: ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Entre para acompanhar sua academia.',
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: email,
                  autofillHints: const [AutofillHints.username],
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Informe seu e-mail.'
                      : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: password,
                  obscureText: !visible,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => submit(),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    suffixIcon: IconButton(
                      tooltip: visible ? 'Ocultar senha' : 'Mostrar senha',
                      onPressed: () => setState(() => visible = !visible),
                      icon: Icon(
                        visible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Informe sua senha.'
                      : null,
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Entrar na academia'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: busy ? null : () => context.go('/forgot-password'),
                  child: const Text('Esqueci minha senha'),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Acesso restrito à equipe convidada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Scaffold(
      body: Row(
        children: [
          if (MediaQuery.sizeOf(context).width >= 1000)
            Expanded(child: marketing),
          Expanded(child: login),
        ],
      ),
    );
  }
}
