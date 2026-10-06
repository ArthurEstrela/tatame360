import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/session.dart';
import '../shared/ui.dart';

class TeamPage extends ConsumerStatefulWidget {
  const TeamPage({super.key});

  @override
  ConsumerState<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends ConsumerState<TeamPage> {
  int revision = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.read(sessionProvider);
    if (!session.manager) {
      return const EmptyState(
        'Acesso restrito',
        'A equipe pode ser gerenciada por owners e gestores.',
        icon: Icons.lock_outline,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(
          'Equipe e acessos',
          'Convide pessoas e mantenha somente os acessos necessários.',
          action: FilledButton.icon(
            onPressed: () => _invite(session),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Convidar pessoa'),
          ),
        ),
        KeyedSubtree(
          key: ValueKey(revision),
          child: LoadView(
            load: () => session.api.get('${session.base}/team'),
            builder: (data, reload) {
              final result = Map<String, dynamic>.from(data as Map);
              final members = (result['members'] as List)
                  .cast<Map<String, dynamic>>();
              final invitations = (result['invitations'] as List)
                  .cast<Map<String, dynamic>>();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Pessoas com acesso',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ...members.map((member) => _memberCard(member, session)),
                  const SizedBox(height: 28),
                  const Text(
                    'Convites',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  if (invitations.isEmpty)
                    const EmptyState(
                      'Nenhum convite enviado',
                      'Os convites pendentes e anteriores aparecerão aqui.',
                      icon: Icons.mark_email_unread_outlined,
                    )
                  else
                    ...invitations.map(
                      (invitation) => _invitationCard(invitation, session),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _memberCard(Map<String, dynamic> member, Session session) {
    final role = member['role'] as String;
    final active = member['active'] == true;
    final canEdit =
        role != 'OWNER' && (session.owner || !['MANAGER'].contains(role));
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: CircleAvatar(
          child: Text((member['name'] as String).substring(0, 1).toUpperCase()),
        ),
        title: Text(
          member['name'] as String,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${member['email']} · ${_roleLabel(role)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AccessPill(active: active),
            if (canEdit) ...[
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Editar acesso',
                onPressed: () => _editMember(member, session),
                icon: const Icon(Icons.manage_accounts_outlined),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _invitationCard(Map<String, dynamic> invitation, Session session) {
    final status = invitation['status'] as String;
    final expiry = DateTime.parse(invitation['expiresAt'].toString()).toLocal();
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: const CircleAvatar(child: Icon(Icons.mail_outline)),
        title: Text(
          invitation['name'] as String,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${invitation['email']} · ${_roleLabel(invitation['role'] as String)}\nExpira em ${DateFormat('dd/MM/yyyy HH:mm').format(expiry)}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InvitationPill(status: status),
            if (status == 'PENDING') ...[
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Revogar convite',
                onPressed: () => _revoke(invitation, session),
                icon: const Icon(Icons.link_off_outlined),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _invite(Session session) async {
    final name = TextEditingController();
    final email = TextEditingController();
    String role = 'INSTRUCTOR';
    bool busy = false;
    Map<String, dynamic>? result;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Convidar para a equipe'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Papel'),
                  items: [
                    if (session.owner)
                      const DropdownMenuItem(
                        value: 'MANAGER',
                        child: Text('Gestor'),
                      ),
                    const DropdownMenuItem(
                      value: 'INSTRUCTOR',
                      child: Text('Professor'),
                    ),
                    const DropdownMenuItem(
                      value: 'FRONT_DESK',
                      child: Text('Recepção'),
                    ),
                  ],
                  onChanged: (value) => role = value!,
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
                      if (name.text.trim().length < 2 ||
                          !email.text.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Informe nome e e-mail válidos.'),
                          ),
                        );
                        return;
                      }
                      setDialog(() => busy = true);
                      try {
                        result = Map<String, dynamic>.from(
                          await session.api.post(
                            '${session.base}/invitations',
                            {
                              'name': name.text.trim(),
                              'email': email.text.trim(),
                              'role': role,
                            },
                          ) as Map,
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) showError(context, e);
                        setDialog(() => busy = false);
                      }
                    },
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Criar convite'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    email.dispose();
    if (result == null || !mounted) return;
    setState(() => revision++);
    final token = result!['token'] as String;
    final link = kIsWeb
        ? '${Uri.base.origin}${Uri.base.path}#/invite?token=${Uri.encodeQueryComponent(token)}'
        : token;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convite criado'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Envie este link à pessoa convidada. Ele pode ser usado uma vez e expira em 7 dias.',
              ),
              const SizedBox(height: 16),
              SelectableText(
                link,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Link copiado.')));
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar link'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _editMember(Map<String, dynamic> member, Session session) async {
    String role = member['role'] as String;
    bool active = member['active'] == true, busy = false;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text('Acesso de ${member['name']}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Papel'),
                  items: [
                    if (session.owner)
                      const DropdownMenuItem(
                        value: 'MANAGER',
                        child: Text('Gestor'),
                      ),
                    const DropdownMenuItem(
                      value: 'INSTRUCTOR',
                      child: Text('Professor'),
                    ),
                    const DropdownMenuItem(
                      value: 'FRONT_DESK',
                      child: Text('Recepção'),
                    ),
                  ],
                  onChanged: (value) => role = value!,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: active,
                  onChanged: (value) => setDialog(() => active = value),
                  title: const Text('Acesso ativo'),
                  subtitle: const Text(
                    'Ao desativar, a pessoa perde acesso imediatamente.',
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
                        await session.api.patch(
                          '${session.base}/team/${member['id']}',
                          {'role': role, 'active': active},
                        );
                        if (context.mounted) Navigator.pop(context);
                        setState(() => revision++);
                      } catch (e) {
                        if (context.mounted) showError(context, e);
                        setDialog(() => busy = false);
                      }
                    },
              child: const Text('Salvar acesso'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _revoke(Map<String, dynamic> invitation, Session session) async {
    if (!await confirmAction(
      context,
      'Revogar convite?',
      'O link deixará de funcionar imediatamente.',
    )) {
      return;
    }
    try {
      await session.api.post(
        '${session.base}/invitations/${invitation['id']}/revoke',
        {},
      );
      setState(() => revision++);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }
}

class _AccessPill extends StatelessWidget {
  const _AccessPill({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: active ? const Color(0xFFEAF2EA) : const Color(0xFFF0F0ED),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      active ? 'Ativo' : 'Inativo',
      style: TextStyle(
        color: active ? green : muted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _InvitationPill extends StatelessWidget {
  const _InvitationPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final label =
        {
          'PENDING': 'Pendente',
          'ACCEPTED': 'Aceito',
          'REVOKED': 'Revogado',
          'EXPIRED': 'Expirado',
        }[status] ??
        status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status == 'PENDING'
            ? const Color(0xFFFFF0D6)
            : const Color(0xFFEAF2EA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: status == 'PENDING' ? const Color(0xFF825611) : green,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _roleLabel(String role) =>
    {
      'OWNER': 'Proprietário',
      'MANAGER': 'Gestor',
      'INSTRUCTOR': 'Professor',
      'FRONT_DESK': 'Recepção',
    }[role] ??
    role;
