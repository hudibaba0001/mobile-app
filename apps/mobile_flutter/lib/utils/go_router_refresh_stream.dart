import 'dart:async';
import 'package:flutter/widgets.dart';

/// A [ChangeNotifier] that wraps a [Stream] and notifies listeners when the stream emits.
///
/// This is useful for making a [Stream] work with GoRouter's [GoRouter.refreshListenable].
class GoRouterRefreshStream extends ChangeNotifier {
  /// Creates a [GoRouterRefreshStream] that wraps the given [stream].
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
