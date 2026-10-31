/// Volunteer professional available for student matching (MVP roster).
class Professional {
  final String id;
  final String name;
  final String role;
  final String specialty;
  final String bio;
  final String? phone;
  final List<String> availableModes;
  final bool active;

  const Professional({
    required this.id,
    required this.name,
    required this.role,
    required this.specialty,
    required this.bio,
    this.phone,
    this.availableModes = const ['chat', 'call'],
    this.active = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'role': role,
        'specialty': specialty,
        'bio': bio,
        if (phone != null) 'phone': phone,
        'availableModes': availableModes,
        'active': active,
      };

  factory Professional.fromMap(Map<String, dynamic> map, {String? id}) {
    return Professional(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Volunteer',
      role: map['role'] as String? ?? 'Volunteer',
      specialty: map['specialty'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      phone: map['phone'] as String?,
      availableModes: (map['availableModes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['chat', 'call'],
      active: map['active'] as bool? ?? true,
    );
  }
}
