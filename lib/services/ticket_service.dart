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
      await _supabaseClient
          .from('tickets')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId);
    } catch (e) {
      throw Exception('Error al actualizar ticket: $e');
    }
  }

  // Eliminar ticket
  Future<void> deleteTicket(String ticketId) async {
    try {
      await _supabaseClient
          .from('tickets')
          .delete()
          .eq('id', ticketId);
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
          .replaceAll(RegExp(r'[^\w\.]'), '_') // Reemplazar caracteres especiales
          .replaceAll(RegExp(r'_+'), '_')      // Reemplazar múltiples _ por uno solo
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
      if (errorMessage.contains('403') || errorMessage.contains('Unauthorized')) {
        throw Exception('No tienes permiso para subir imágenes. '
            'Asegúrate de que las políticas RLS del bucket están configuradas correctamente.');
      } else if (errorMessage.contains('bucket') || errorMessage.contains('not found')) {
        throw Exception('El bucket "ticket-images" no existe. '
            'Por favor, créalo en Supabase Storage primero.');
      } else if (errorMessage.contains('size') || errorMessage.contains('quota')) {
        throw Exception('La imagen es muy grande. Intenta con una imagen más pequeña.');
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

      // Obtener ID del técnico
      final techResponse = await _supabaseClient
          .from('technicians')
          .select('id')
          .eq('user_id', userId)
          .single();

      final technicianId = techResponse['id'] as String;

      // Obtener tickets asignados a este técnico
      final response = await _supabaseClient
          .from('tickets')
          .select()
          .eq('assigned_to', technicianId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener tickets del técnico: $e');
      return [];
    }
  }
}

