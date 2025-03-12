class UserModel {
  final String id;
  final String name;
  final String email;
  final String password; // In a real app, this would be hashed
  final String photoUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.photoUrl,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      createdAt: data['createdAt'] != null 
        ? DateTime.parse(data['createdAt']) 
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

