// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RegisterViewModel)
final registerViewModelProvider = RegisterViewModelFamily._();

final class RegisterViewModelProvider
    extends $NotifierProvider<RegisterViewModel, RegisterState> {
  RegisterViewModelProvider._({
    required RegisterViewModelFamily super.from,
    required Role super.argument,
  }) : super(
         retry: disableRetry,
         name: r'registerViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$registerViewModelHash();

  @override
  String toString() {
    return r'registerViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RegisterViewModel create() => RegisterViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegisterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegisterState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RegisterViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$registerViewModelHash() => r'21868d9e0066535287abb09e5a49f4ba39c4902f';

final class RegisterViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          RegisterViewModel,
          RegisterState,
          RegisterState,
          RegisterState,
          Role
        > {
  RegisterViewModelFamily._()
    : super(
        retry: disableRetry,
        name: r'registerViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RegisterViewModelProvider call(Role role) =>
      RegisterViewModelProvider._(argument: role, from: this);

  @override
  String toString() => r'registerViewModelProvider';
}

abstract class _$RegisterViewModel extends $Notifier<RegisterState> {
  late final _$args = ref.$arg as Role;
  Role get role => _$args;

  RegisterState build(Role role);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RegisterState, RegisterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RegisterState, RegisterState>,
              RegisterState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
