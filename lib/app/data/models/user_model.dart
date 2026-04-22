class GatiUser {
  GatiUser({
    required this.email,
    required this.fullName,
    required this.password,
  });

  final String email;
  final String fullName;
  final String password;

  Map<String, dynamic> toMap() => {
    'email': email,
    'fullName': fullName,
    'password': password,
  };

  factory GatiUser.fromMap(Map<String, dynamic> map) => GatiUser(
    email: map['email'] as String,
    fullName: map['fullName'] as String,
    password: map['password'] as String,
  );
}
