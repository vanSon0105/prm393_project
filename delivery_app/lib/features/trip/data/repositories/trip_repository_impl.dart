import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_local_datasource.dart';

class TripRepositoryImpl implements TripRepository {
  const TripRepositoryImpl(this._dataSource);
  final TripLocalDataSource _dataSource;

  @override
  List<Trip> getTrips() => _dataSource.fetchTrips();
}
