import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/trip_theme.dart';
import 'features/trip/presentation/screens/trip_page.dart';

/// Standalone preview of Huy Hoang's three trip interfaces.
void main() => runApp(
  ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: createAppTheme(),
      home: const TripApp(),
    ),
  ),
);
