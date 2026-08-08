import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../widgets/app_button.dart';

/// Shown when Firebase could not be reached at launch.
///
/// Deliberately **not** a route: the router's redirects are built around
/// account state, and a failure that happens before any account can be read
/// is not a navigation decision. This sits above the router instead, so the
/// gate costs the routing architecture nothing.
///
/// The wording is the app's own. A `[core/no-app]` platform exception tells a
/// user nothing they can act on, and the message may carry project
/// identifiers — the underlying error is kept for diagnostics and never put
/// on screen.
class FirebaseUnavailableScreen extends StatelessWidget {
  final VoidCallback onRetry;

  /// True while a retry is in flight, so the control cannot be hammered.
  final bool retrying;

  const FirebaseUnavailableScreen({
    super.key,
    required this.onRetry,
    this.retrying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 44,
                  color: context.c.dotInactive,
                ),
                const SizedBox(height: 18),
                Text(
                  "MyPetFit can't connect",
                  textAlign: TextAlign.center,
                  style: context.t.h3,
                ),
                const SizedBox(height: 10),
                Text(
                  // Says what is true and what is safe, and asks for the one
                  // thing the user can actually change.
                  'We could not reach the service that keeps your pets and '
                  'their reports. Check your connection and try again — '
                  'nothing on this device has been lost.',
                  textAlign: TextAlign.center,
                  style: context.t.bodyText,
                ),
                const SizedBox(height: 26),
                AppButton(
                  label: retrying ? 'Trying…' : 'Try again',
                  height: AppTheme.ctaHeightCompact,
                  onPressed: retrying ? null : onRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
