// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_module.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(apiRepository)
final apiRepositoryProvider = ApiRepositoryProvider._();

final class ApiRepositoryProvider
    extends $FunctionalProvider<ApiRepository, ApiRepository, ApiRepository>
    with $Provider<ApiRepository> {
  ApiRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiRepositoryHash();

  @$internal
  @override
  $ProviderElement<ApiRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApiRepository create(Ref ref) {
    return apiRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiRepository>(value),
    );
  }
}

String _$apiRepositoryHash() => r'46f7a54f9dcb12ce6b788e95af2f8dc412a19a77';

@ProviderFor(authenticationRepository)
final authenticationRepositoryProvider = AuthenticationRepositoryProvider._();

final class AuthenticationRepositoryProvider
    extends
        $FunctionalProvider<
          AuthenticationRepository,
          AuthenticationRepository,
          AuthenticationRepository
        >
    with $Provider<AuthenticationRepository> {
  AuthenticationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authenticationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authenticationRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthenticationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthenticationRepository create(Ref ref) {
    return authenticationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthenticationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthenticationRepository>(value),
    );
  }
}

String _$authenticationRepositoryHash() =>
    r'188229402afc1365225e8a54b32ae3b89cb20646';

@ProviderFor(appSharePreferences)
final appSharePreferencesProvider = AppSharePreferencesProvider._();

final class AppSharePreferencesProvider
    extends
        $FunctionalProvider<
          SharePreferenceRepository,
          SharePreferenceRepository,
          SharePreferenceRepository
        >
    with $Provider<SharePreferenceRepository> {
  AppSharePreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSharePreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSharePreferencesHash();

  @$internal
  @override
  $ProviderElement<SharePreferenceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharePreferenceRepository create(Ref ref) {
    return appSharePreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharePreferenceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharePreferenceRepository>(value),
    );
  }
}

String _$appSharePreferencesHash() =>
    r'0c3067f47ad2e724fa40859b0c506ebc6b0307da';
