import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/technician.dart';

class AdminService {
  final SupabaseClient _supabaseClient;

  AdminService(this._supabaseClient);

  // Obtener lista de técnicos activos
  Future<List<Technician>> getActiveTechnicians() async {
    try {
      debugPrint('🔍 Obteniendo técnicos activos...');

      // Intentar desde tabla technicians
      try {
        final response = await _supabaseClient
            .from('technicians')
            .select()
            .eq('status', 'activo');

        debugPrint('📋 Respuesta tabla technicians: $response');

        final technicians = (response as List)
            .map((e) => Technician.fromJson(e as Map<String, dynamic>))
            .toList();

        debugPrint(
          '✅ Técnicos obtenidos desde technicians: ${technicians.length}',
        );
        if (technicians.isNotEmpty) {
          for (var tech in technicians) {
            debugPrint('   - ${tech.fullName} (${tech.email})');
          }
          return technicians;
        }
      } catch (e) {
        debugPrint('⚠️ No se pudo consultar tabla technicians: $e');
      }

      // Fallback: buscar en profiles con role 'technician'
      debugPrint('🔄 Buscando en profiles con role=technician...');
      try {
        final response = await _supabaseClient
            .from('profiles')
            .select()
            .eq('role', 'technician');

        debugPrint('📋 Respuesta tabla profiles: $response');

        final technicians = (response as List).map((e) {
          return Technician(
            id: e['id'] as String,
            userId: e['id'] as String,
            fullName: e['full_name'] as String? ?? 'Sin nombre',
            email: e['email'] as String? ?? 'sin@email.com',
            specialization: null,
            status: 'activo',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();

        debugPrint(
          '✅ Técnicos obtenidos desde profiles: ${technicians.length}',
        );
        for (var tech in technicians) {
          debugPrint('   - ${tech.fullName} (${tech.email})');
        }
        return technicians;
      } catch (e) {
        debugPrint('❌ Error al consultar profiles: $e');
        throw Exception('No se encontraron técnicos: $e');
      }
    } catch (e) {
      debugPrint('❌ Error al obtener técnicos: $e');
      throw Exception('Error al obtener técnicos: $e');
    }
  }

  // Asignar ticket a técnico usando RPC
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

      if (technicianId == null) {
        throw Exception('ID del técnico no puede ser null');
      }

      debugPrint(
        '🔧 Usando RPC para asignar ticket $ticketId a técnico $technicianId',
      );

      // Llamar función RPC (más seguro que UPDATE directo)
      final response = await _supabaseClient.rpc(
        'assign_ticket_to_technician',
        params: {'p_ticket_id': ticketId, 'p_technician_id': technicianId},
      );

      debugPrint('✅ Respuesta RPC: $response');

      if (response is List && response.isNotEmpty) {
        final result = response.first as Map;
        final success = result['success'] as bool?;
        final message = result['message'] as String?;

        if (success == true) {
          debugPrint('✅ Ticket asignado exitosamente: $message');
        } else {
          throw Exception('Error en RPC: $message');
        }
      } else {
        throw Exception('Respuesta inesperada de RPC');
      }
    } catch (e) {
      debugPrint('❌ Error al asignar ticket: $e');
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
