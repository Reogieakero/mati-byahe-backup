class UserModel {
  final String email;
  final String role;

  UserModel({required this.email, required this.role});

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      email: map['email'] ?? '',
      role: map['role'] ?? 'Passenger',
    );
  }

  bool get isDriver => role.toLowerCase() == 'driver';
  bool get isPassenger => role.toLowerCase() == 'passenger';
}
