import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../providers/driver_earnings_provider.dart';
import '../widgets/earnings/earnings_breakdown_section.dart';
import '../widgets/earnings/earnings_chart.dart';
import '../widgets/earnings/earnings_statistics_card.dart';
import '../widgets/earnings/earnings_summary_card.dart';
import '../widgets/earnings/earnings_time_filter.dart';

class DriverEarningsPage extends ConsumerWidget {
  const DriverEarningsPage({super.key});

  static final DateTime _referenceDate = DateTime(2026, 10, 7);
  static const _weeklyEarnings = {
    'T2': 120000,
    'T3': 180000,
    'T4': 135000,
    'T5': 230000,
    'T6': 190000,
    'T7': 250000,
    'CN': 145000,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsState = ref.watch(driverEarningsProvider);
    final notifier = ref.read(driverEarningsProvider.notifier);
    final dateRangeText = _dateRangeText(earningsState);

    return Theme(
      data: AppTheme.light(),
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              AppScreenHeader(
                eyebrow: 'Thu nhập',
                title: 'Tổng quan thu nhập',
                actionIcon: Icons.calendar_month_outlined,
                onActionPressed: () =>
                    _selectDateRange(context, ref, earningsState),
              ),
              const SizedBox(height: 28),
              EarningsTimeFilter(
                selectedFilter: earningsState.selectedFilter,
                dateRangeText: dateRangeText,
                onFilterChanged: notifier.selectFilter,
                onCustomRangeTap: () =>
                    _selectDateRange(context, ref, earningsState),
              ),
              const SizedBox(height: 16),
              EarningsSummaryCard(
                earnings: _formatCurrency(1250000),
                dateRangeText: dateRangeText,
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(
                    child: EarningsStatisticsCard(
                      icon: Icons.route_outlined,
                      label: 'Quãng đường',
                      value: '186.5 km',
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: EarningsStatisticsCard(
                      icon: Icons.local_taxi_outlined,
                      label: 'Chuyến đi',
                      value: '24 chuyến',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const EarningsChart(data: _weeklyEarnings),
              const SizedBox(height: 16),
              const EarningsBreakdownSection(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange(
    BuildContext context,
    WidgetRef ref,
    DriverEarningsState state,
  ) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2027, 12, 31),
      initialDateRange:
          state.selectedDateRange ??
          DateTimeRange(
            start: _referenceDate.subtract(const Duration(days: 6)),
            end: _referenceDate,
          ),
      helpText: 'Chọn khoảng thời gian',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      saveText: 'Lưu',
    );

    if (range != null) {
      ref.read(driverEarningsProvider.notifier).selectDateRange(range);
    }
  }

  String _dateRangeText(DriverEarningsState state) {
    final customRange = state.selectedDateRange;
    if (customRange != null) {
      return '${_formatDate(customRange.start)} - '
          '${_formatDate(customRange.end)}';
    }

    final days = switch (state.selectedFilter) {
      'Hôm nay' => 1,
      '30 ngày' => 30,
      _ => 7,
    };
    if (days == 1) return _formatDate(_referenceDate);

    final startDate = _referenceDate.subtract(Duration(days: days - 1));
    return '${_formatDate(startDate)} - ${_formatDate(_referenceDate)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatCurrency(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
      buffer.write(digits[index]);
    }
    return '$buffer ₫';
  }
}
