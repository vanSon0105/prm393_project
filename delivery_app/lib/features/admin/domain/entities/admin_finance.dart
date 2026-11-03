class AdminBankAccount {
  const AdminBankAccount({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    this.transferNote = '',
  });

  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final String transferNote;

  factory AdminBankAccount.fromJson(Map<String, dynamic> json) =>
      AdminBankAccount(
        bankName: json['bank_name']?.toString() ?? '',
        accountNumber: json['account_number']?.toString() ?? '',
        accountHolder: json['account_holder']?.toString() ?? '',
        transferNote: json['transfer_note']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
    'bank_name': bankName.trim(),
    'account_number': accountNumber.trim(),
    'account_holder': accountHolder.trim(),
    'transfer_note': transferNote.trim(),
  };
}

enum TopUpStatus { pending, approved, rejected }

class DriverTopUpRequest {
  const DriverTopUpRequest({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.amount,
    required this.createdAt,
    required this.status,
    this.transferReference = '',
    this.proofUrl = '',
  });

  final int id;
  final int driverId;
  final String driverName;
  final int amount;
  final DateTime createdAt;
  final TopUpStatus status;
  final String transferReference;
  final String proofUrl;

  factory DriverTopUpRequest.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final driverId = json['driver_id'] as int;
    final amount = json['amount'] as int;
    if (id <= 0 || driverId <= 0 || amount <= 0) {
      throw const FormatException(
        'Invalid top-up request identifiers or amount',
      );
    }
    final status = json['status']?.toString().toLowerCase();
    return DriverTopUpRequest(
      id: id,
      driverId: driverId,
      driverName: json['driver_name']?.toString() ?? '',
      amount: amount,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: TopUpStatus.values.firstWhere(
        (value) => value.name == status,
        orElse: () => throw const FormatException('Invalid top-up status'),
      ),
      transferReference: json['transfer_reference']?.toString() ?? '',
      proofUrl: json['proof_url']?.toString() ?? '',
    );
  }
}
