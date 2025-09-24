import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserCache {
  static const _profileKey = "cached_profile";
  static const _businessKey = "cached_business";
  static const _avatarUrlKey = "cached_avatar_url";
  static const _lastFetchKey = "last_profile_fetch";

  /// Guarda el perfil en cache
  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_profileKey, jsonEncode(profile)),
      prefs.setString(_lastFetchKey, DateTime.now().millisecondsSinceEpoch.toString()),
      // Cache avatar URL separately for faster access
      if (profile['avatar_url'] != null)
        prefs.setString(_avatarUrlKey, profile['avatar_url']),
    ]);
  }

  /// Obtiene el perfil del cache
  static Future<Map<String, dynamic>?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_profileKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  /// Obtiene solo la URL del avatar (más rápido)
  static Future<String?> getAvatarUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarUrlKey);
  }

  /// Verifica si el cache es reciente (menos de 1 hora)
  static Future<bool> isCacheRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchString = prefs.getString(_lastFetchKey);
    if (lastFetchString == null) return false;
    
    final lastFetch = DateTime.fromMillisecondsSinceEpoch(int.parse(lastFetchString));
    final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
    
    return lastFetch.isAfter(hourAgo);
  }

  /// Guarda los datos del negocio en cache
  static Future<void> saveBusiness(Map<String, dynamic> business) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_businessKey, jsonEncode(business));
  }

  /// Obtiene los datos del negocio del cache
  static Future<Map<String, dynamic>?> getBusiness() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_businessKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  /// Limpia todo el cache
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_profileKey),
      prefs.remove(_businessKey),
      prefs.remove(_avatarUrlKey),
      prefs.remove(_lastFetchKey),
    ]);
  }

  /// Actualiza ambos (perfil y negocio) a la vez
  static Future<void> updateAll({
    required Map<String, dynamic> profile,
    Map<String, dynamic>? business,
  }) async {
    await saveProfile(profile);
    if (business != null) {
      await saveBusiness(business);
    }
  }
}