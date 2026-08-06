import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/assets.dart';
import '../../config/theme.dart';
import '../../providers/app_startup_provider.dart';
import '../../providers/pet_info_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/design_image.dart';

/// The one place cloud state is restored.
///
/// Reached by redirect whenever someone is signed in but their data has not
/// been loaded yet — cold launch, email sign-in, Google sign-in, and a
/// restart alike — so none of those paths need their own loading code. The
/// screen does not navigate: finishing moves [AppStartupProvider] to
/// `ready`, the router notices, and the router decides where to go.
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    // After the first frame: initialize() notifies its listeners, and the
    // router is one of them — calling it during build would mutate state
    // the widget tree is in the middle of reading.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    await context.read<AppStartupProvider>().initialize(
          petInfo: context.read<PetInfoProvider>(),
          quiz: context.read<QuizProvider>(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final startup = context.watch<AppStartupProvider>();

    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DesignImage(
                  AppAssets.logoFor(context.c.brightness),
                  width: 180,
                  semanticLabel: 'MyPetFit',
                ),
                const SizedBox(height: 36),
                if (startup.hasFailed)
                  _Failed(onRetry: _load)
                else
                  const _Loading(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(context.c.action),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Getting your pets ready…',
          textAlign: TextAlign.center,
          style: AppTheme.font(size: 14, color: context.c.body, height: 1.5),
        ),
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  final VoidCallback onRetry;

  const _Failed({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.cloud_off_rounded, size: 40, color: context.c.dotInactive),
        const SizedBox(height: 16),
        Text(
          "Couldn't load your data",
          textAlign: TextAlign.center,
          style: context.t.h3,
        ),
        const SizedBox(height: 10),
        Text(
          'Check your connection and try again. Nothing has been lost — '
          'your pets and reports are safe.',
          textAlign: TextAlign.center,
          style: context.t.bodyText,
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Try again',
          height: AppTheme.ctaHeightCompact,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
