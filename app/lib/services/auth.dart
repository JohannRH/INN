import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  /// Register a new user
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    try {
      // Extract data from body
      final email = body['email'] as String;
      final password = body['password'] as String;
      final name = body['name'] as String;
      final role = body['role'] as String;
      final phone = body['phone'] as String?;

      // Step 1: Sign up with Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('No se pudo crear el usuario');
      }

      final userId = authResponse.user!.id;

      // Step 2: Create profile manually (just like Python backend did)
      await _supabase.from('profiles').insert({
        'id': userId,
        'role': role,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar_url': body['avatar_url'],
      });

      // Step 3: If business, create business record
      if (role == 'negocio') {
        await _supabase.from('businesses').insert({
          'user_id': userId,
          'name': body['business_name'],
          'nit': body['nit'],
          'address': body['address'],
          'description': body['description'],
          'logo_url': body['avatar_url'],
          'latitude': body['latitude'],
          'longitude': body['longitude'],
          'type_id': body['type_id'],
        });
      }

      // Step 4: Sign in to get the session (like Python backend did)
      final loginResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (loginResponse.session == null) {
        throw Exception('Error al iniciar sesión después del registro');
      }

      // Return session data
      return {
        'access_token': loginResponse.session!.accessToken,
        'refresh_token': loginResponse.session!.refreshToken,
        'user': {
          'id': loginResponse.user!.id,
          'email': loginResponse.user!.email,
          'role': role,
          'name': name,
          'phone': phone,
          'avatar_url': body['avatar_url'],
        },
      };
    } on AuthException catch (e) {
      throw Exception(_parseAuthError(e));
    } on PostgrestException catch (e) {
      // Clean up auth user if profile creation failed
      throw Exception('Error en la base de datos: ${e.message}');
    } catch (e) {
      throw Exception('Error al registrar usuario: ${e.toString()}');
    }
  }

  /// Login existing user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Credenciales inválidas');
      }

      // Fetch user profile to get role and name
      final profile = await _supabase
          .from('profiles')
          .select('id, name, email, role, avatar_url, phone')
          .eq('id', response.user!.id)
          .maybeSingle();

      return {
        'access_token': response.session?.accessToken ?? '',
        'refresh_token': response.session?.refreshToken ?? '',
        'user': {
          'id': response.user!.id,
          'email': response.user!.email,
          'name': profile?['name'],
          'role': profile?['role'],
          'avatar_url': profile?['avatar_url'],
          'phone': profile?['phone'],
        },
      };
    } on AuthException catch (e) {
      throw Exception(_parseAuthError(e));
    } catch (e) {
      throw Exception('Error al iniciar sesión: ${e.toString()}');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: ${e.toString()}');
    }
  }

  /// Get current session
  Session? getCurrentSession() {
    return _supabase.auth.currentSession;
  }

  /// Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Parse Supabase auth errors into user-friendly messages
  String _parseAuthError(AuthException error) {
    switch (error.message) {
      case 'Invalid login credentials':
        return 'Credenciales inválidas';
      case 'Email not confirmed':
        return 'Por favor confirma tu correo electrónico';
      case 'User already registered':
        return 'Este correo ya está registrado';
      default:
        if (error.message.contains('already exists')) {
          return 'Este correo ya está registrado';
        }
        return error.message;
    }
  }
}