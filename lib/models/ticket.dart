class Ticket {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category; // 'Tecnología' o 'Administrativo'
  final String priority; // 'baja', 'media', 'alta'
  final String status; // 'abierto', 'en_progreso', 'cerrado'
  final String? imageUrl; // URL de la imagen adjunta (opcional)
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignedTo; // ID del técnico asignado

  Ticket({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.assignedTo,
  });

  // Convertir desde JSON (Supabase)
  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String? ?? 'Tecnología',
      priority: json['priority'] as String,
      status: json['status'] as String,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      assignedTo: json['assigned_to'] as String?,
    );
  }

  // Convertir a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'image_url': imageUrl,
      'assigned_to': assignedTo,
    };
  }
}
