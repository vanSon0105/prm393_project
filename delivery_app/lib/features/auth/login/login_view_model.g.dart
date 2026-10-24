// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LoginViewModel)
final loginViewModelProvider = LoginViewModelProvider._();

final class LoginViewModelProvider
    extends $AsyncNotifierProvider<LoginViewModel, PostResponse> {
  LoginViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: disableRetry,
        name: r'loginViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginViewModelHash();

  @$internal
  @override
  LoginViewModel create() => LoginViewModel();
}

String _$loginViewModelHash() => r'c376a72d398f32dbf9244f97dfbb7bfa669834d9';

abstract class _$LoginViewModel extends $AsyncNotifier<PostResponse> {
  FutureOr<PostResponse> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PostResponse>, PostResponse>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PostResponse>, PostResponse>,
              AsyncValue<PostResponse>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
