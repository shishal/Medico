import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/result.dart';
import '../domain/plan_tier.dart';
import 'checkout_env.dart';

part 'checkout_launcher.g.dart';

/// Opens the web checkout in the **device browser** — never an in-app
/// purchase, WebView, or payment form.
class CheckoutLauncher {
  CheckoutLauncher({required this.checkoutUri, required this.launch});

  final Uri? checkoutUri;
  final Future<bool> Function(Uri uri) launch;

  /// [plan] is passed as a query param so the web page can pre-select it.
  Future<Result<void>> openCheckout({required PlanTier plan}) async {
    if (plan == PlanTier.free) {
      return const Failure('The Free plan does not need checkout.');
    }

    final base = checkoutUri;
    if (base == null) {
      return const Failure(
        'Checkout is not set up yet. Please try again later.',
      );
    }

    final uri = base.replace(
      queryParameters: {...base.queryParameters, 'plan': plan.name},
    );

    try {
      final opened = await launch(uri);
      if (!opened) {
        return const Failure(
          'Could not open the checkout page in your browser.',
        );
      }
      return const Success(null);
    } catch (_) {
      return const Failure('Could not open the checkout page in your browser.');
    }
  }
}

@Riverpod(keepAlive: true)
CheckoutLauncher checkoutLauncher(Ref ref) {
  return CheckoutLauncher(
    checkoutUri: CheckoutEnv.urlOrNull,
    // externalApplication = the system browser, not an in-app WebView.
    launch: (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
  );
}
