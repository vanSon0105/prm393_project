enum LoginStatus {
  approved(value: 'APPROVED'),
  pending(value: 'PENDING'),
  reject(value: 'REJECTED');

  final String value;

  const LoginStatus({required this.value});

  static LoginStatus valueOf(String value) {
    return LoginStatus.values.firstWhere((e) => e.value == value);
  }
}
