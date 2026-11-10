// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppViewModel)
final appViewModelProvider = AppViewModelProvider._();

final class AppViewModelProvider
    extends $NotifierProvider<AppViewModel, AppState> {
  AppViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: disableRetry,
        name: r'appViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appViewModelHash();

  @$internal
  @override
  AppViewModel create() => AppViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppState>(value),
    );
  }
}

String _$appViewModelHash() => r'32aec2255509d47fad255380c102f8b27a446229';

abstract class _$AppViewModel extends $Notifier<AppState> {
  AppState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppState, AppState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppState, AppState>,
              AppState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
