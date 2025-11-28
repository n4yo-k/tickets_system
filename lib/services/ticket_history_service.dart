import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class TicketHistoryService {
  final SupabaseClient _supabaseClient;

  TicketHistoryService(this._supabaseClient);

  // Registrar cambio de estado
  Future<void> recordStatusChange({
    required String ticketId,
    required String oldStatus,
    required String newStatus,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Registrando cambio de estado: $oldStatus → $newStatus');

      await _supabaseClient.from('ticket_history').insert({
        'ticket_id': ticketId,
        'user_id': userId,
        'action': 'status_change',
        'old_value': oldStatus,
        'new_value': newStatus,
      });

      debugPrint('Historial registrado correctamente');
    } catch (e) {
      debugPrint('Error al registrar cambio de estado: $e');
      throw Exception('Error al registrar cambio: $e');
    }
  }

  // Registrar asignación
  Future<void> recordAssignment({
    required String ticketId,
    required String? technicianId,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Registrando asignación a técnico: $technicianId');

      await _supabaseClient.from('ticket_history').insert({
        'ticket_id': ticketId,
        'user_id': userId,
        'action': 'assigned',
        'old_value': null,
        'new_value': technicianId,
      });

      debugPrint('Asignación registrada correctamente');
    } catch (e) {
      debugPrint('Error al registrar asignación: $e');
      throw Exception('Error al registrar asignación: $e');
    }
  }

  // Obtener historial de un ticket
  Future<List<Map<String, dynamic>>> getTicketHistory(String ticketId) async {
    try {
      final response = await _supabaseClient
          .from('ticket_history')
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener historial: $e');
    }
  }
}
