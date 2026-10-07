// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dioClient)
final dioClientProvider = DioClientProvider._();

final class DioClientProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  DioClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioClientHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dioClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioClientHash() => r'86a7ce57d18dfaeedf8ba37046a5eb76a14711a9';

@ProviderFor(apiProvider)
final apiProviderProvider = ApiProviderProvider._();

final class ApiProviderProvider
    extends $FunctionalProvider<ApiProvider, ApiProvider, ApiProvider>
    with $Provider<ApiProvider> {
  ApiProviderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiProviderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiProviderHash();

  @$internal
  @override
  $ProviderElement<ApiProvider> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApiProvider create(Ref ref) {
    return apiProvider(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiProvider value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiProvider>(value),
    );
  }
}

String _$apiProviderHash() => r'08fb268dbb3edba16fd66b43ffb035d31e2e499d';
