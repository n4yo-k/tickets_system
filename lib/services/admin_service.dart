import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/technician.dart';

class AdminService {
  final SupabaseClient _supabaseClient;

  AdminService(this._supabaseClient);

  // Obtener lista de técnicos activos
  Future<List<Technician>> getActiveTechnicians() async {
    try {
      debugPrint('Obteniendo técnicos activos...');

      final response = await _supabaseClient
          .from('technicians')
          .select()
          .eq('status', 'activo');

      final technicians = (response as List)
          .map((e) => Technician.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint('Técnicos obtenidos: ${technicians.length}');
      return technicians;
    } catch (e) {
      debugPrint('Error al obtener técnicos: $e');
      throw Exception('Error al obtener técnicos: $e');
    }
  }

  // Asignar ticket a técnico
  Future<void> assignTicketToTechnician({
    required String ticketId,
    required String? technicianId,
  }) async {
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar que el usuario actual es admin
      final userRole = await _getUserRole(currentUser.id);
      if (userRole != 'admin') {
        throw Exception('Solo administradores pueden asignar tickets');
      }

      debugPrint('Asignando ticket $ticketId a técnico $technicianId');

      // Actualizar ticket
      await _supabaseClient
          .from('tickets')
          .update({'assigned_to': technicianId})
          .eq('id', ticketId);

      debugPrint('Ticket asignado exitosamente');
    } catch (e) {
      debugPrint('Error al asignar ticket: $e');
      throw Exception('Error al asignar ticket: $e');
    }
  }

  // Obtener rol del usuario
  Future<String> _getUserRole(String userId) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      return response['role'] as String? ?? 'user';
    } catch (e) {
      return 'user';
    }
  }

  // Crear nuevo técnico (solo admin)
  Future<Technician> createTechnician({
    required String userId,
    required String fullName,
    required String email,
    required String specialization,
  }) async {
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Creando técnico: $fullName');

      final response = await _supabaseClient
          .from('technicians')
          .insert({
            'user_id': userId,
            'full_name': fullName,
            'email': email,
            'specialization': specialization,
            'status': 'activo',
          })
          .select()
          .single();

      return Technician.fromJson(response);
    } catch (e) {
      debugPrint('Error al crear técnico: $e');
      throw Exception('Error al crear técnico: $e');
    }
  }
}
