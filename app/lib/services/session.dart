import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, 
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Keys
  static const String _tokenKey = 'secure_access_token';
  static const String _userIdKey = 'secure_user_id';
  static const String _userEmailKey = 'secure_user_email';
  static const String _expiryKey = 'secure_session_expiry';

  /// Guardar sesión de forma segura
  static Future<void> saveSession(
    String token,
    Map<String, dynamic> user, {
    Duration? expiresIn,
  }) async {
    final expiryTime = DateTime.now().add(expiresIn ?? const Duration(days: 7));

    await Future.wait([
      _secureStorage.write(key: _tokenKey, value: token),
      _secureStorage.write(key: _userIdKey, value: user['id']?.toString() ?? ''),
      _secureStorage.write(key: _userEmailKey, value: user['email']?.toString() ?? ''),
      _secureStorage.write(
          key: _expiryKey, value: expiryTime.millisecondsSinceEpoch.toString()),
    ]);
  }

  /// Obtener sesión
  static Future<Map<String, dynamic>?> getSession() async {
    final token = await _secureStorage.read(key: _tokenKey);
    final id = await _secureStorage.read(key: _userIdKey);
    final email = await _secureStorage.read(key: _userEmailKey);
    final expiryString = await _secureStorage.read(key: _expiryKey);

    if (token == null || id == null) return null;

    // Validar expiración
    if (expiryString != null) {
      final expiryTime =
          DateTime.fromMillisecondsSinceEpoch(int.parse(expiryString));
      if (DateTime.now().isAfter(expiryTime)) {
        await clearSession();
        return null;
      }
    }

    return {
      "access_token": token,
      "user": {
        "id": id,
        "email": email,
      },
      "expires_at": expiryString != null
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(expiryString))
          : null,
    };
  }

  /// Eliminar sesión
  static Future<void> clearSession() async {
    await Future.wait([
      _secureStorage.delete(key: _tokenKey),
      _secureStorage.delete(key: _userIdKey),
      _secureStorage.delete(key: _userEmailKey),
      _secureStorage.delete(key: _expiryKey),
    ]);
  }

  /// Verificar si existe sesión válida
  static Future<bool> hasValidSession() async {
    final session = await getSession();
    return session != null;
  }

  /// Obtener solo el token
  static Future<String?> getToken() async {
    final session = await getSession();
    return session?['access_token'];
  }

  /// Refrescar fecha de expiración
  static Future<void> refreshSessionExpiry({Duration? newExpiry}) async {
    final expiryTime =
        DateTime.now().add(newExpiry ?? const Duration(days: 7));
    await _secureStorage.write(
        key: _expiryKey, value: expiryTime.millisecondsSinceEpoch.toString());
  }
}
