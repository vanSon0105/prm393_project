class AdminBankAccount {
  const AdminBankAccount({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    this.qrCode = '',
    this.qrBytes,
    this.qrFileName,
  });

  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final String qrCode;
  final List<int>? qrBytes;
  final String? qrFileName;

  factory AdminBankAccount.fromJson(Map<String, dynamic> json) =>
      AdminBankAccount(
        bankName: json['bank_name']?.toString() ?? '',
        accountNumber: json['bank_account_number']?.toString() ?? '',
        accountHolder: json['bank_account_name']?.toString() ?? '',
        qrCode: json['bank_qr_code']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
    'bank_name': bankName.trim(),
    'bank_account_number': accountNumber.trim(),
    'bank_account_name': accountHolder.trim(),
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
    this.proofUrl = '',
    this.rejectReason = '',
  });

  final int id;
  final int driverId;
  final String driverName;
  final int amount;
  final DateTime createdAt;
  final TopUpStatus status;
  final String proofUrl;
  final String rejectReason;

  factory DriverTopUpRequest.fromJson(Map<String, dynamic> json) {
    final id = (json['transaction_id'] as num).toInt();
    final driverId = (json['driver_id'] as num).toInt();
    final amount = (json['balance'] as num).toInt();
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
      createdAt: DateTime.parse(json['time'] as String),
      status: TopUpStatus.values.firstWhere(
        (value) => value.name == status,
        orElse: () => throw const FormatException('Invalid top-up status'),
      ),
      proofUrl: json['image_transaction']?.toString() ?? '',
      rejectReason: json['reject_reason']?.toString() ?? '',
    );
  }
}
