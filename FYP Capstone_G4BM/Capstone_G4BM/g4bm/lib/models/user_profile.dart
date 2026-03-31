class UserProfile {
  final String id;
  final String name;
  final String username;
  final String email;
  final String passwordHash; // Added for security
  final String location;
  final String gender;
  final String dob;

  UserProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.location,
    required this.gender,
    required this.dob,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['_id'].toString(),
      name: map['name'] ?? 'User',
      username: map['username'] ?? '@username',
      email: map['email'] ?? '',
      passwordHash: map['password'] ?? '', // Maps to 'password' column in DB
      location: map['location'] ?? 'Malaysia',
      gender: map['gender'] ?? 'Not specified',
      dob: map['dob'] ?? 'DD-MM-YYYY',
    );
  }
}
