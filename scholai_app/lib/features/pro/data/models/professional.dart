/// Volunteer professional available for student matching (MVP roster).
class Professional {
  final String id;
  final String name;
  final String role;
  final String specialty;
  final String bio;
  final String? phone;
  final List<String> availableModes;

  const Professional({
    required this.id,
    required this.name,
    required this.role,
    required this.specialty,
    required this.bio,
    this.phone,
    this.availableModes = const ['chat', 'call'],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'role': role,
        'specialty': specialty,
        'bio': bio,
        if (phone != null) 'phone': phone,
        'availableModes': availableModes,
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
    );
  }
}

/// Seed roster for MVP — used locally and optionally written to `/professionals`.
const kSeedProfessionals = [
  Professional(
    id: 'pro_campus_counsellor',
    name: 'Adaora Okeke',
    role: 'Campus counsellor volunteer',
    specialty: 'Academic stress & adjustment',
    bio:
        'UI counselling centre volunteer. Warm listener for exam pressure, '
        'burnout, and settling into campus life — not clinical therapy.',
    phone: '+2348012345678',
    availableModes: ['chat', 'call'],
  ),
  Professional(
    id: 'pro_peer_support',
    name: 'Chinedu Eze',
    role: 'Peer support volunteer',
    specialty: 'Relationships & student life',
    bio:
        'Trained peer supporter. Good for money stress, friendship friction, '
        'and “just needing another student who gets it.”',
    phone: null,
    availableModes: ['chat'],
  ),
  Professional(
    id: 'pro_licensed_trainee',
    name: 'Fatima Bello',
    role: 'Licensed trainee (supervised)',
    specialty: 'Habits & emotional regulation',
    bio:
        'Psychology trainee under supervision. Helps with habits, sleep routines, '
        'and reflective conversation — not addiction treatment or diagnosis.',
    phone: '+2348098765432',
    availableModes: ['chat', 'call'],
  ),
];
