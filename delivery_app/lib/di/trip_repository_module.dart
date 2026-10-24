import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/trip/data/datasources/trip_local_datasource.dart';
import '../features/trip/data/repositories/trip_repository_impl.dart';
import '../features/trip/domain/repositories/trip_repository.dart';

final tripLocalDataSourceProvider = Provider((ref) => TripLocalDataSource());
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepositoryImpl(ref.watch(tripLocalDataSourceProvider));
});
