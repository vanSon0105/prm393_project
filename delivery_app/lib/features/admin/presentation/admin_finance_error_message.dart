import 'package:delivery_app/data/network/base/exception.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

String adminFinanceLoadErrorMessage(Object? error) {
  if (error is ApiException && error.httpCode == 404) {
    return LocaleKeys.admin_finance_api_unavailable.tr();
  }
  return LocaleKeys.admin_finance_load_error.tr();
}
