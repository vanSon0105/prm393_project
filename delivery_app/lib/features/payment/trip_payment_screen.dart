import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../generated/locale_keys.g.dart';

import '../../core/theme/app_theme.dart';
import '../../gen/assets.gen.dart';

class TripPaymentScreen extends StatefulWidget {
  const TripPaymentScreen({super.key});

  @override
  State<TripPaymentScreen> createState() => _TripPaymentScreenState();
}

class _TripPaymentScreenState extends State<TripPaymentScreen> {
  static const blue = AppColors.blue;
  String paymentMethod = 'cash';

  Widget paymentOption({
    required String value,
    required SvgGenImage icon,
    required String title,
    required String subtitle,
  }) {
    final selected = paymentMethod == value;

    return InkWell(
      onTap: () => setState(() => paymentMethod = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.blueSoft : AppColors.surfaceStrong,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? blue : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            icon.svg(
              width: 30,
              height: 30,
              colorFilter: const ColorFilter.mode(blue, BlendMode.srcIn),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(value: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            LocaleKeys.payment_title.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      LocaleKeys.payment_total.tr(),
                      style: const TextStyle(color: AppColors.whiteSoft),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '42.000đ',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LocaleKeys.payment_trip_code.tr(
                        namedArgs: const {'code': 'TRIP-2026-001'},
                      ),
                      style: const TextStyle(color: AppColors.whiteSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceStrong,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.circle, color: AppColors.blue, size: 14),
                        SizedBox(width: 12),
                        Expanded(child: Text('12 Nguyễn Huệ')),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 24,
                          child: VerticalDivider(thickness: 2),
                        ),
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.stop, color: AppColors.text, size: 16),
                        SizedBox(width: 12),
                        Expanded(child: Text('86 Võ Văn Tần')),
                      ],
                    ),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(LocaleKeys.payment_fare.tr()),
                        const Text('40.000đ'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(LocaleKeys.payment_service_fee.tr()),
                        const Text('2.000đ'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                LocaleKeys.payment_method.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              RadioGroup<String>(
                groupValue: paymentMethod,
                onChanged: (value) {
                  if (value != null) setState(() => paymentMethod = value);
                },
                child: Column(
                  children: [
                    paymentOption(
                      value: 'cash',
                      icon: Assets.images.icCash,
                      title: LocaleKeys.payment_cash.tr(),
                      subtitle: LocaleKeys.payment_cash_description.tr(),
                    ),
                    paymentOption(
                      value: 'qr',
                      icon: Assets.images.icQr,
                      title: LocaleKeys.payment_bank_qr.tr(),
                      subtitle: LocaleKeys.payment_bank_qr_description.tr(),
                    ),
                  ],
                ),
              ),
              if (paymentMethod == 'qr')
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceStrong,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Assets.images.icQr.svg(
                        width: 140,
                        height: 140,
                        colorFilter: const ColorFilter.mode(
                          AppColors.text,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        LocaleKeys.payment_qr_demo.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSoft),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(LocaleKeys.payment_selected_demo.tr()),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    LocaleKeys.payment_confirm.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
