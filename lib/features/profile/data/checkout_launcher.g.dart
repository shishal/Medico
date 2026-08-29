// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_launcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(checkoutLauncher)
final checkoutLauncherProvider = CheckoutLauncherProvider._();

final class CheckoutLauncherProvider
    extends
        $FunctionalProvider<
          CheckoutLauncher,
          CheckoutLauncher,
          CheckoutLauncher
        >
    with $Provider<CheckoutLauncher> {
  CheckoutLauncherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkoutLauncherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkoutLauncherHash();

  @$internal
  @override
  $ProviderElement<CheckoutLauncher> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CheckoutLauncher create(Ref ref) {
    return checkoutLauncher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckoutLauncher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckoutLauncher>(value),
    );
  }
}

String _$checkoutLauncherHash() => r'd81c58ccadd17897c211c922340e9ecbca4215cc';
