import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/design_image.dart';

/// The nearby-vet search this screen hands to the platform.
///
/// Apple Maps on iOS and Google Maps elsewhere, both as https links rather
/// than custom schemes: a web URL needs no `LSApplicationQueriesSchemes`
/// entry, and it degrades to the browser on a device with no maps app
/// instead of failing to resolve.
@visibleForTesting
Uri vetSearchUri({TargetPlatform? platform}) =>
    (platform ?? defaultTargetPlatform) == TargetPlatform.iOS
        ? Uri.parse('https://maps.apple.com/?q=veterinarian')
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=veterinarian',
          );

/// Screen 23b — shown instead of the report card when the score lands in the
/// Critical band.
class VetAlertScreen extends StatelessWidget {
  const VetAlertScreen({super.key, @visibleForTesting this.launcher});

  /// Injected by tests. Production uses `url_launcher`.
  final Future<bool> Function(Uri)? launcher;

  /// Opens a nearby-vet search.
  ///
  /// This screen is raised when the assessment says an animal needs
  /// professional attention, and its primary action was an empty callback —
  /// the one screen in the app where a dead button costs something.
  Future<void> _findAVet(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = vetSearchUri();

    var opened = false;
    try {
      opened = await (launcher?.call(uri) ??
          launchUrl(uri, mode: LaunchMode.externalApplication));
    } catch (_) {
      opened = false;
    }

    // A device with nothing able to open a map is unusual but not
    // impossible, and silence on this screen is the failure that matters.
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't open maps on this device. Search for a nearby "
            'veterinarian to get your pet seen.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [context.c.surface, context.c.bandCriticalTint],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: DesignImage(
                    AppAssets.vetAlert,
                    width: 230,
                    shadow: true,
                    semanticLabel: 'Concerned puppy',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Let's get a vet involved",
                  textAlign: TextAlign.center,
                  style: context.t.h1.copyWith(fontSize: 26, letterSpacing: -1),
                ),
                const SizedBox(height: 12),
                Text(
                  'Some answers suggest your pet needs professional attention '
                  "soon. This isn't a diagnosis — but a check-up this week is "
                  'the right next step.',
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    size: 14.5,
                    color: context.c.bodyStrong,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 26),
                AppButton(
                  label: 'Find a vet near me',
                  variant: AppButtonVariant.danger,
                  height: AppTheme.ctaHeightCompact,
                  icon: Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: context.c.onAccent,
                  ),
                  onPressed: () => _findAVet(context),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'View the full report',
                  variant: AppButtonVariant.outline,
                  height: 52,
                  onPressed: () => context.pushReplacement(AppRoutes.report),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

