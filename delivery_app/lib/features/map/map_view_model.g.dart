// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MapViewModel)
final mapViewModelProvider = MapViewModelFamily._();

final class MapViewModelProvider
    extends $NotifierProvider<MapViewModel, MapState> {
  MapViewModelProvider._({
    required MapViewModelFamily super.from,
    required Role super.argument,
  }) : super(
         retry: null,
         name: r'mapViewModelProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mapViewModelHash();

  @override
  String toString() {
    return r'mapViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MapViewModel create() => MapViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MapViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mapViewModelHash() => r'b88f4ec7befd5fb2b995aa136370d6e6f262f767';

final class MapViewModelFamily extends $Family
    with
        $ClassFamilyOverride<MapViewModel, MapState, MapState, MapState, Role> {
  MapViewModelFamily._()
    : super(
        retry: null,
        name: r'mapViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  MapViewModelProvider call(Role role) =>
      MapViewModelProvider._(argument: role, from: this);

  @override
  String toString() => r'mapViewModelProvider';
}

abstract class _$MapViewModel extends $Notifier<MapState> {
  late final _$args = ref.$arg as Role;
  Role get role => _$args;

  MapState build(Role role);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MapState, MapState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MapState, MapState>,
              MapState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
