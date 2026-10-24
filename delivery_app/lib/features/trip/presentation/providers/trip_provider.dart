import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../di/trip_repository_module.dart';
import '../../domain/entities/trip.dart';

final tripsProvider = NotifierProvider<TripsNotifier, List<Trip>>(
  TripsNotifier.new,
);

class TripsNotifier extends Notifier<List<Trip>> {
  @override
  List<Trip> build() =>
      List.unmodifiable(ref.watch(tripRepositoryProvider).getTrips());

  void _update(String code, Trip Function(Trip) update) {
    state = List.unmodifiable([
      for (final trip in state)
        if (trip.code == code) update(trip) else trip,
    ]);
  }

  void cancel(String code) => _update(
    code,
    (trip) => trip.status == TripStatus.approaching
        ? trip.copyWith(status: TripStatus.cancelled)
        : trip,
  );

  void advance(String code) => _update(
    code,
    (trip) => switch (trip.status) {
      TripStatus.approaching => trip.copyWith(status: TripStatus.pickedUp),
      TripStatus.pickedUp => trip.copyWith(
        status: TripStatus.completed,
        paid: true,
      ),
      _ => trip,
    },
  );

  void rate(String code, int stars) {
    if (stars < 1 || stars > 5) return;
    _update(
      code,
      (trip) => trip.status == TripStatus.completed && trip.rating == null
          ? trip.copyWith(rating: stars)
          : trip,
    );
  }
}
