import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverEarningsState {
  const DriverEarningsState({
    this.selectedFilter = '7 ngày',
    this.selectedDateRange,
  });

  final String selectedFilter;
  final DateTimeRange? selectedDateRange;

  DriverEarningsState copyWith({
    String? selectedFilter,
    DateTimeRange? selectedDateRange,
    bool clearDateRange = false,
  }) {
    return DriverEarningsState(
      selectedFilter: selectedFilter ?? this.selectedFilter,
      selectedDateRange: clearDateRange
          ? null
          : selectedDateRange ?? this.selectedDateRange,
    );
  }
}

class DriverEarningsNotifier extends Notifier<DriverEarningsState> {
  @override
  DriverEarningsState build() => const DriverEarningsState();

  void selectFilter(String filter) {
    state = state.copyWith(selectedFilter: filter, clearDateRange: true);
  }

  void selectDateRange(DateTimeRange range) {
    state = state.copyWith(
      selectedFilter: 'Tùy chọn',
      selectedDateRange: range,
    );
  }
}

final driverEarningsProvider =
    NotifierProvider<DriverEarningsNotifier, DriverEarningsState>(
      DriverEarningsNotifier.new,
    );
