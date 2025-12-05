import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ticket.dart';

class TicketService {
  final SupabaseClient _supabaseClient;

  TicketService(this._supabaseClient);

  // Crear un nuevo ticket
  Future<Ticket> createTicket({
    required String title,
    required String description,
    required String category,
    required String priority,
    String? imageUrl,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Creando ticket con imageUrl: $imageUrl');

      final response = await _supabaseClient
          .from('tickets')
          .insert({
            'user_id': userId,
            'title': title,
            'description': description,
            'category': category,
            'priority': priority,
            'status': 'abierto',
            'image_url': imageUrl,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      debugPrint('Ticket creado exitosamente. Respuesta: $response');
      return Ticket.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear ticket: $e');
    }
  }

  // Obtener tickets del usuario actual
  Stream<List<Ticket>> getUserTickets() {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    return _supabaseClient
        .from('tickets')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => [for (var item in data) Ticket.fromJson(item)]);
  }

  // Obtener un ticket específico
  Future<Ticket> getTicket(String ticketId) async {
    try {
      final response = await _supabaseClient
          .from('tickets')
          .select()
          .eq('id', ticketId)
          .single();

      return Ticket.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener ticket: $e');
    }
  }

  // Actualizar estado del ticket
  Future<void> updateTicketStatus(String ticketId, String newStatus) async {
    try {
      debugPrint('🔧 Actualizando estado del ticket $ticketId a $newStatus');

      // Usar RPC para mayor seguridad (similar a assignTicketToTechnician)
      final response = await _supabaseClient.rpc(
        'update_ticket_status',
        params: {'p_ticket_id': ticketId, 'p_new_status': newStatus},
      );

      debugPrint('✅ Respuesta RPC: $response');

      if (response is List && response.isNotEmpty) {
        final result = response.first as Map;
        final success = result['success'] as bool?;
        final message = result['message'] as String?;

        if (success == true) {
          debugPrint('✅ Estado actualizado exitosamente: $message');
        } else {
          throw Exception('Error en RPC: $message');
        }
      } else {
        throw Exception('Respuesta inesperada de RPC');
      }
    } catch (e) {
      debugPrint('❌ Error al actualizar ticket: $e');
      throw Exception('Error al actualizar ticket: $e');
    }
  }

  // Eliminar ticket
  Future<void> deleteTicket(String ticketId) async {
    try {
      await _supabaseClient.from('tickets').delete().eq('id', ticketId);
    } catch (e) {
      throw Exception('Error al eliminar ticket: $e');
    }
  }

  // Subir imagen a Storage
  Future<String> uploadTicketImage(XFile imageFile) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Generar nombre de archivo único - sin espacios
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Sanitizar nombre del archivo: remover espacios y caracteres especiales
      final sanitizedName = imageFile.name
          .replaceAll(
            RegExp(r'[^\w\.]'),
            '_',
          ) // Reemplazar caracteres especiales
          .replaceAll(RegExp(r'_+'), '_') // Reemplazar múltiples _ por uno solo
          .toLowerCase();

      final fileName = '${timestamp}_$sanitizedName';

      debugPrint('Iniciando upload de imagen: $fileName');
      debugPrint('Usuario ID: $userId');

      // Leer bytes del archivo
      final imageBytes = await imageFile.readAsBytes();
      debugPrint('Tamaño de archivo: ${imageBytes.length} bytes');

      try {
        // Subir a Supabase Storage
        final storagePath = await _supabaseClient.storage
            .from('ticket-images')
            .uploadBinary(
              fileName,
              imageBytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );

        debugPrint('Upload exitoso: $storagePath');

        // Guardar solo el nombre del archivo (más corto)
        // La URL completa se construirá cuando se necesite mostrar
        debugPrint('Archivo guardado para BD: $fileName');

        return fileName;
      } catch (storageError) {
        debugPrint('Error en storage: $storageError');
        rethrow;
      }
    } catch (e) {
      final errorMessage = e.toString();
      debugPrint('Error al subir imagen: $errorMessage');

      // Mensajes de error personalizados
      if (errorMessage.contains('403') ||
          errorMessage.contains('Unauthorized')) {
        throw Exception(
          'No tienes permiso para subir imágenes. '
          'Asegúrate de que las políticas RLS del bucket están configuradas correctamente.',
        );
      } else if (errorMessage.contains('bucket') ||
          errorMessage.contains('not found')) {
        throw Exception(
          'El bucket "ticket-images" no existe. '
          'Por favor, créalo en Supabase Storage primero.',
        );
      } else if (errorMessage.contains('size') ||
          errorMessage.contains('quota')) {
        throw Exception(
          'La imagen es muy grande. Intenta con una imagen más pequeña.',
        );
      }

      throw Exception('Error al subir imagen: $errorMessage');
    }
  }

  // Obtener todos los tickets (para admin)
  Future<List<Ticket>> getAllTickets() async {
    try {
      final response = await _supabaseClient
          .from('tickets')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener tickets: $e');
    }
  }

  // Obtener tickets sin asignar (para admin)
  Future<List<Ticket>> getUnassignedTickets() async {
    try {
      final response = await _supabaseClient
          .from('tickets')
          .select()
          .isFilter('assigned_to', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener tickets sin asignar: $e');
    }
  }

  // Obtener tickets asignados al técnico actual (para técnico)
  Future<List<Ticket>> getTechnicianTickets() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('🔍 Obteniendo tickets asignados al técnico...');

      String technicianId = '';

      // Intentar obtener ID del técnico de la tabla technicians
      try {
        final techResponse = await _supabaseClient
            .from('technicians')
            .select('id')
            .eq('user_id', userId)
            .single();

        technicianId = techResponse['id'] as String;
        debugPrint('✅ Técnico encontrado en tabla technicians: $technicianId');
      } catch (e) {
        debugPrint('⚠️ No encontrado en technicians, buscando fallback...');

        // Fallback: obtener ID del técnico desde profiles
        try {
          final profileResponse = await _supabaseClient
              .from('technicians')
              .select('id')
              .eq('user_id', userId);

          if ((profileResponse as List).isNotEmpty) {
            technicianId = profileResponse.first['id'] as String;
            debugPrint('✅ Técnico encontrado con fallback: $technicianId');
          } else {
            debugPrint('❌ Técnico no encontrado en ninguna tabla');
            return [];
          }
        } catch (fallbackError) {
          debugPrint('❌ Error en fallback: $fallbackError');
          return [];
        }
      }

      // Obtener tickets asignados a este técnico
      debugPrint('🎫 Buscando tickets asignados a técnico: $technicianId');
      debugPrint('🆔 User ID logueado: $userId');

      // Primero, obtener TODOS los tickets para ver cuáles tienen assigned_to
      final allTickets = await _supabaseClient
          .from('tickets')
          .select('id, title, assigned_to')
          .order('created_at', ascending: false);

      debugPrint('📊 Total de tickets en BD: ${(allTickets as List).length}');
      for (var ticket in allTickets as List) {
        final assignedTo = ticket['assigned_to'];
        debugPrint(
          '   - ${ticket['title']} | assigned_to: $assignedTo (tipo: ${assignedTo?.runtimeType})',
        );
      }

      // Ahora hacer la búsqueda con el filtro
      debugPrint('🔎 Filtrando por assigned_to = "$technicianId"...');
      final response = await _supabaseClient
          .from('tickets')
          .select()
          .eq('assigned_to', technicianId)
          .order('created_at', ascending: false);

      final tickets = (response as List)
          .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint(
        '📋 Se encontraron ${tickets.length} tickets asignados al técnico',
      );
      if (tickets.isEmpty) {
        debugPrint(
          '⚠️ No hay coincidencias. Verifica que assigned_to coincida exactamente con: $technicianId',
        );
      }
      return tickets;
    } catch (e) {
      debugPrint('❌ Error al obtener tickets del técnico: $e');
      return [];
    }
  }
}
