enum ProApplicationStatus {
  pending,
  approved,
  rejected;

  String get wire => name;

  String get label => switch (this) {
        ProApplicationStatus.pending => 'Pending review',
        ProApplicationStatus.approved => 'Approved',
        ProApplicationStatus.rejected => 'Not approved',
      };

  static ProApplicationStatus fromWire(String? value) => switch (value) {
        'approved' => ProApplicationStatus.approved,
        'rejected' => ProApplicationStatus.rejected,
        _ => ProApplicationStatus.pending,
      };
}

const kProCredentials = [
  'Campus counsellor',
  'Peer supporter',
  'Psychology trainee',
  'Licensed clinician',
  'Other',
];

const kProSupportAreas = [
  'Exams',
  'Money',
  'Relationships',
  'Habits',
  'General listening',
];

class ProApplication {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String credential;
  final String organization;
  final String bio;
  final List<String> areas;
  final ProApplicationStatus status;
  final String? reviewNote;

  const ProApplication({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.credential,
    required this.organization,
    required this.bio,
    required this.areas,
    required this.status,
    this.reviewNote,
  });

  factory ProApplication.fromMap(Map<String, dynamic> map, {required String uid}) {
    return ProApplication(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      credential: map['credential'] as String? ?? '',
      organization: map['organization'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      areas: (map['areas'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      status: ProApplicationStatus.fromWire(map['status'] as String?),
      reviewNote: map['reviewNote'] as String?,
    );
  }
}
