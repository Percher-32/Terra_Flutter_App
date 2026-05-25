import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_storage.dart' as token_storage;

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  final _storage = const FlutterSecureStorage();
  String? _memoryToken;

  Future<void> saveToken(String token) async {
    _memoryToken = token;

    if (kIsWeb) {
      token_storage.setItem('auth_token', token);
    } else {
      await _storage.write(key: 'auth_token', value: token);
    }
  }

  Future<String?> getToken() async {
    if (_memoryToken != null) return _memoryToken;

    if (kIsWeb) {
      _memoryToken = token_storage.getItem('auth_token');
    } else {
      _memoryToken = await _storage.read(key: 'auth_token');
    }

    return _memoryToken;
  }

  Future<void> clearToken() async {
    _memoryToken = null;

    if (kIsWeb) {
      token_storage.removeItem('auth_token');
    } else {
      await _storage.delete(key: 'auth_token');
    }
  }

  Future<void> saveRefreshToken(String refreshtoken) async {
    if (!kIsWeb) {
      await _storage.write(key: 'ref_token', value: refreshtoken);
    }
  }

  Future<String?> getRefreshToken() async {
    if (!kIsWeb) {
      _memoryToken = await _storage.read(key: 'ref_token');
    }

    return _memoryToken;
  }

  Future<void> clearRefreshToken() async {
    _memoryToken = null;

    if (kIsWeb) {
      token_storage.removeItem('ref_token');
    } else {
      await _storage.delete(key: 'ref_token');
    }
  }
}

final tokenmanager = TokenManager();
