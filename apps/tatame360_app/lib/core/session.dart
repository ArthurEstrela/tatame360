import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api.dart';

final sessionProvider = Provider<Session>((ref) {
  final session = Session(Api());
  ref.onDispose(session.dispose);
  return session;
});

class Session extends ChangeNotifier {
  Session(this.api) {
    api.onExpired = () {
      user = null;
      academy = null;
      notifyListeners();
    };
  }
  final Api api;
  Map<String, dynamic>? user, academy;
  bool loading = true;
  bool get authenticated => user != null;
  bool get manager => ['OWNER', 'MANAGER'].contains(academy?['role']);
  bool get owner => academy?['role'] == 'OWNER';
  String get base => '/academies/${academy!['id']}';
  List<Map<String, dynamic>> get academies =>
      (user?['academies'] as List? ?? []).cast<Map<String, dynamic>>();
  Future<void> initialize() async {
    try {
      await api.restore();
      await _loadUser();
    } catch (_) {
      user = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    await api.login(email, password);
    await _loadUser();
    notifyListeners();
  }

  Future<void> _loadUser() async {
    user = Map<String, dynamic>.from(await api.get('/me') as Map);
    academy = academies.isEmpty ? null : academies.first;
  }

  void selectAcademy(String id) {
    academy = academies.firstWhere((a) => a['id'] == id);
    notifyListeners();
  }

  Future<void> logout() async {
    await api.logout();
    user = null;
    academy = null;
    notifyListeners();
  }
}
