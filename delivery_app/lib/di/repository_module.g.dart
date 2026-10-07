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
