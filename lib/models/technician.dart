class Technician {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String? specialization; // 'redes', 'software', 'hardware', 'general'
  final String status; // 'activo', 'inactivo'
  final DateTime createdAt;
  final DateTime updatedAt;

  Technician({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.specialization,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convertir desde JSON (Supabase)
  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      specialization: json['specialization'] as String?,
      status: json['status'] as String? ?? 'activo',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'specialization': specialization,
      'status': status,
    };
  }
}
