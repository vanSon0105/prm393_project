// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tripRealtimeService)
final tripRealtimeServiceProvider = TripRealtimeServiceProvider._();

final class TripRealtimeServiceProvider
    extends $FunctionalProvider<TripService, TripService, TripService>
    with $Provider<TripService> {
  TripRealtimeServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripRealtimeServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripRealtimeServiceHash();

  @$internal
  @override
  $ProviderElement<TripService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TripService create(Ref ref) {
    return tripRealtimeService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripService>(value),
    );
  }
}

String _$tripRealtimeServiceHash() =>
    r'11e063c2b88f69f24a32664dbb1f9fbb0434d712';
