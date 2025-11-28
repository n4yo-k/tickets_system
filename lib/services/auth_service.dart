import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabaseClient;

  AuthService(this._supabaseClient);

  // Registro de usuario
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      // Validar contraseña
      if (password.length < 6) {
        throw Exception('La contraseña debe tener mínimo 6 caracteres');
      }

      // Validar email
      if (!_isValidEmail(email)) {
        throw Exception('El formato del email es inválido');
      }

      // Intentar registro con Supabase Auth
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName ?? '',
          'role': 'user', // Por defecto es usuario
        },
      );

      return response;
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        throw Exception('Este correo ya está en uso');
      }
      throw Exception('Error en el registro: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // Inicio de sesión
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('Credenciales inválidas');
      }
      throw Exception('Error en el login: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  // Obtener usuario actual
  User? getCurrentUser() {
    return _supabaseClient.auth.currentUser;
  }

  // Obtener stream de cambios de autenticación
  Stream<AuthState> authStateChanges() {
    return _supabaseClient.auth.onAuthStateChange;
  }

  // Validar email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
