import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverTermsConsent extends Notifier<bool> {
  @override
  bool build() => false;

  void accept() => state = true;
}

final driverTermsConsentProvider = NotifierProvider<DriverTermsConsent, bool>(
  DriverTermsConsent.new,
);
