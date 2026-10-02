import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import 'http_adapter.dart';

class Api {
  Api() {
    configureAdapter(dio);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          if (_token != null) o.headers['Authorization'] = 'Bearer $_token';
          h.next(o);
        },
        onError: (e, h) async {
          final r = e.requestOptions;
          if (e.response?.statusCode == 401 &&
              !r.path.startsWith('/auth/') &&
              r.extra['retried'] != true) {
            try {
              await restore();
              r.extra['retried'] = true;
              r.headers['Authorization'] = 'Bearer $_token';
              h.resolve(await dio.fetch<dynamic>(r));
              return;
            } catch (_) {
              _token = null;
              onExpired?.call();
            }
          }
          h.next(e);
        },
      ),
    );
  }
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://localhost:18080/api/v1',
      ),
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'X-Tatame-Client': 'app'},
    ),
  );
  final _storage = const FlutterSecureStorage();
  String? _token;
  Future<void>? _refreshing;
  VoidCallback? onExpired;
  Future<void> login(String email, String password) async {
    final r = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email.trim(), 'password': password, 'mobile': !kIsWeb},
    );
    await _accept(r.data!);
  }

  Future<void> _accept(Map<String, dynamic> tokens) async {
    _token = tokens['accessToken'] as String;
    if (!kIsWeb) {
      await _storage.write(
        key: 'tatame.refresh',
        value: tokens['refreshToken'] as String,
      );
    }
  }

  Future<void> restore() =>
      _refreshing ??= _restore().whenComplete(() => _refreshing = null);
  Future<void> _restore() async {
    final token = kIsWeb ? null : await _storage.read(key: 'tatame.refresh');
    final r = await dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'mobile': !kIsWeb, if (!kIsWeb) 'refreshToken': token},
    );
    await _accept(r.data!);
  }

  Future<void> logout() async {
    final token = kIsWeb ? null : await _storage.read(key: 'tatame.refresh');
    await dio.post<dynamic>(
      '/auth/logout',
      data: {'mobile': !kIsWeb, if (!kIsWeb) 'refreshToken': token},
    );
    _token = null;
    if (!kIsWeb) await _storage.delete(key: 'tatame.refresh');
  }

  Future<dynamic> get(String path) async => (await dio.get<dynamic>(path)).data;
  Future<dynamic> post(String path, [Object? data, String? key]) async =>
      (await dio.post<dynamic>(
        path,
        data: data,
        options: Options(
          headers: {'Idempotency-Key': key ?? const Uuid().v4()},
        ),
      )).data;
  Future<dynamic> patch(String path, Object data) async =>
      (await dio.patch<dynamic>(path, data: data)).data;
  static String message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (error.response == null) {
        return 'Não foi possível conectar. Confira sua conexão e tente novamente.';
      }
      if (error.response?.statusCode == 403) {
        return 'Você não tem permissão para esta ação.';
      }
    }
    return 'Não foi possível concluir. Tente novamente.';
  }
}
