class EmergencyContactModel {
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String relation;
  final String address;

  const EmergencyContactModel({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.relation,
    required this.address,
  });

  String get fullName => '$firstName $lastName';
}
