import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  static const String _refreshTokenKey = 'secure_refresh_token';
  static const String _userIdKey = 'secure_user_id';
  static const String _userEmailKey = 'secure_user_email';
  static const String _userNameKey = 'secure_user_name';
  static const String _userRoleKey = 'secure_user_role';
  static const String _userAvatarKey = 'secure_user_avatar';
  static const String _userPhoneKey = 'secure_user_phone';
  static const String _expiryKey = 'secure_session_expiry';

  /// Save session securely
  static Future<void> saveSession(
    String token,
    Map<String, dynamic> user, {
    String? refreshToken,
    Duration? expiresIn,
  }) async {
    final expiryTime = DateTime.now().add(expiresIn ?? const Duration(days: 7));

    await Future.wait([
      _secureStorage.write(key: _tokenKey, value: token),
      if (refreshToken != null)
        _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
      _secureStorage.write(key: _userIdKey, value: user['id']?.toString() ?? ''),
      _secureStorage.write(key: _userEmailKey, value: user['email']?.toString() ?? ''),
      _secureStorage.write(key: _userNameKey, value: user['name']?.toString() ?? ''),
      _secureStorage.write(key: _userRoleKey, value: user['role']?.toString() ?? ''),
      if (user['avatar_url'] != null)
        _secureStorage.write(key: _userAvatarKey, value: user['avatar_url'].toString()),
      if (user['phone'] != null)
        _secureStorage.write(key: _userPhoneKey, value: user['phone'].toString()),
      _secureStorage.write(
          key: _expiryKey, value: expiryTime.millisecondsSinceEpoch.toString()),
    ]);
  }

  /// Get session
  static Future<Map<String, dynamic>?> getSession() async {
    final token = await _secureStorage.read(key: _tokenKey);
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    final id = await _secureStorage.read(key: _userIdKey);
    final email = await _secureStorage.read(key: _userEmailKey);
    final name = await _secureStorage.read(key: _userNameKey);
    final role = await _secureStorage.read(key: _userRoleKey);
    final avatarUrl = await _secureStorage.read(key: _userAvatarKey);
    final phone = await _secureStorage.read(key: _userPhoneKey);
    final expiryString = await _secureStorage.read(key: _expiryKey);

    if (token == null || id == null) return null;

    // Validate expiration
    if (expiryString != null) {
      final expiryTime =
          DateTime.fromMillisecondsSinceEpoch(int.parse(expiryString));
      if (DateTime.now().isAfter(expiryTime)) {
        // Try to refresh the session with Supabase
        if (refreshToken != null) {
          try {
            final response = await Supabase.instance.client.auth.refreshSession();
            if (response.session != null) {
              // Update stored session
              await saveSession(
                response.session!.accessToken,
                {
                  'id': id,
                  'email': email,
                  'name': name,
                  'role': role,
                  'avatar_url': avatarUrl,
                  'phone': phone,
                },
                refreshToken: response.session!.refreshToken,
              );
              return await getSession(); // Return refreshed session
            }
          } catch (e) {
            await clearSession();
            return null;
          }
        } else {
          await clearSession();
          return null;
        }
      }
    }

    return {
      "access_token": token,
      "refresh_token": refreshToken,
      "user": <String, dynamic>{
        "id": id,
        "email": email,
        "name": name,
        "role": role,
        "avatar_url": avatarUrl,
        "phone": phone,
      },
      "expires_at": expiryString != null
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(expiryString))
          : null,
    };
  }

  /// Clear session
  static Future<void> clearSession() async {
    await Future.wait([
      _secureStorage.delete(key: _tokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _secureStorage.delete(key: _userIdKey),
      _secureStorage.delete(key: _userEmailKey),
      _secureStorage.delete(key: _userNameKey),
      _secureStorage.delete(key: _userRoleKey),
      _secureStorage.delete(key: _userAvatarKey),
      _secureStorage.delete(key: _userPhoneKey),
      _secureStorage.delete(key: _expiryKey),
    ]);
  }

  /// Check if valid session exists
  static Future<bool> hasValidSession() async {
    final session = await getSession();
    return session != null;
  }

  /// Get only the token
  static Future<String?> getToken() async {
    final session = await getSession();
    return session?['access_token'];
  }

  /// Refresh session expiry
  static Future<void> refreshSessionExpiry({Duration? newExpiry}) async {
    final expiryTime =
        DateTime.now().add(newExpiry ?? const Duration(days: 7));
    await _secureStorage.write(
        key: _expiryKey, value: expiryTime.millisecondsSinceEpoch.toString());
  }
}