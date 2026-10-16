import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminNavigation extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) {
    if (index >= 0 && index <= 2) state = index;
  }
}

final adminNavigationProvider = NotifierProvider<AdminNavigation, int>(
  AdminNavigation.new,
);
