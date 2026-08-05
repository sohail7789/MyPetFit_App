import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/assets.dart';
import '../../config/theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/design_image.dart';
import '../../widgets/paw_mark.dart';
import '../../widgets/screen_backdrop.dart';
import '../../widgets/social_buttons.dart';

/// One onboarding page's design values.
class _Page {
  final List<Color> gradient;
  final PawWatermark paw;
  final String art;
  final String artLabel;
  final String titleLead;
  final String titleAccent;

  /// Colour of the highlighted word in the title — type on the wash, so it
  /// takes the brightened accent in dark.
  final Color accent;

  /// Fill behind the circular Next button. Separate from [accent] because a
  /// filled shape and type on the canvas resolve to different values in dark
  /// (#5B54B8 vs #A9A3F0).
  final Color buttonFill;

  final String bodyText;
  final Color dotActive;
  final Color dotInactive;

  const _Page({
    required this.gradient,
    required this.paw,
    required this.art,
    required this.artLabel,
    required this.titleLead,
    required this.titleAccent,
    required this.accent,
    required this.buttonFill,
    required this.bodyText,
    required this.dotActive,
    required this.dotInactive,
  });
}

/// How many pages the carousel has. A constant so widgets that only need
/// the count don't have to build the whole palette-resolved list.
const int _pageCount = 3;

/// The three pages, resolved against the active appearance.
///
/// Built per call rather than held as a constant because every colour on the
/// page — wash, paw watermark, accent, dots — differs between light and dark.
List<_Page> _pagesOf(BuildContext context) {
  final c = context.c;
  return <_Page>[
    _Page(
      gradient: c.onboardingWashes[0],
      paw: PawWatermark(
        top: 120,
        left: 18,
        size: 66,
        color: c.actionText,
        opacity: 0.08,
        rotationDegrees: -16,
      ),
      art: AppAssets.onboarding1,
      artLabel: 'Puppy inspecting with a magnifying glass',
      titleLead: 'Understand your\npet’s ',
      titleAccent: 'health',
      accent: c.actionText,
      buttonFill: c.action,
      bodyText:
          "Answer 45 simple questions about your pet's lifestyle, habits and well-being.",
      dotActive: c.action,
      dotInactive: c.dotInactive,
    ),
    _Page(
      gradient: c.onboardingWashes[1],
      paw: PawWatermark(
        top: 132,
        right: 20,
        size: 58,
        color: c.startLight,
        opacity: 0.14,
        rotationDegrees: 14,
      ),
      art: AppAssets.onboarding2,
      artLabel: 'Puppy giving a thumbs up',
      titleLead: 'Get personalized\n',
      titleAccent: 'recommendations',
      accent: c.startLight,
      buttonFill: c.start,
      bodyText:
          'We turn the score into nutrition, dental and grooming picks made for your pet.',
      dotActive: c.startLight,
      dotInactive: c.dotInactiveWarm,
    ),
    _Page(
      gradient: c.onboardingWashes[2],
      paw: PawWatermark(
        top: 118,
        left: -8,
        size: 72,
        color: c.actionText,
        opacity: 0.07,
        rotationDegrees: -20,
      ),
      art: AppAssets.onboarding3,
      artLabel: 'Puppy leaping with joy',
      titleLead: 'Better health,\n',
      titleAccent: 'happier pets',
      accent: c.actionText,
      buttonFill: c.action,
      bodyText:
          'Track progress over time, follow reminders and give your pet the best life possible.',
      dotActive: c.action,
      dotInactive: c.dotInactive,
    ),
  ];
}

/// Screens 02–04 — the three-page onboarding carousel.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Onboarding is only marked complete on the way out, so backing out mid-way
  /// leaves the user where they were.
  Future<void> _leave(String route) async {
    await context.read<OnboardingProvider>().completeOnboarding();
    if (mounted) context.go(route);
  }

  void _next() => _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );

  @override
  Widget build(BuildContext context) {
    final pages = _pagesOf(context);
    final page = pages[_index];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: page.gradient,
            stops: const [0, 0.58, 1],
          ),
        ),
        child: Stack(
          children: [
            page.paw,
            SafeArea(
              child: Column(
                children: [
                  // Pages 1–2 offer Skip; page 3 reserves the same height.
                  SizedBox(
                    height: 56,
                    child: _index == _pageCount - 1
                        ? null
                        : Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 26),
                              child: GestureDetector(
                                onTap: () => _leave(AppRoutes.signIn),
                                child: Text(
                                  'Skip',
                                  style: AppTheme.font(
                                    size: 15,
                                    weight: FontWeight.w600,
                                    color: context.c.body,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: pages.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Center(
                          child: DesignImage(
                            pages[i].art,
                            height: 322,
                            shadow: true,
                            semanticLabel: pages[i].artLabel,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _Caption(
                    page: page,
                    index: _index,
                    onNext: _next,
                    onCreate: () => _leave(AppRoutes.signUp),
                    onLogin: () => _leave(AppRoutes.signIn),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  final _Page page;
  final int index;
  final VoidCallback onNext;
  final VoidCallback onCreate;
  final VoidCallback onLogin;

  const _Caption({
    required this.page,
    required this.index,
    required this.onNext,
    required this.onCreate,
    required this.onLogin,
  });

  bool get _isLast => index == _pageCount - 1;

  @override
  Widget build(BuildContext context) {
    final dots = PageDots(
      count: _pageCount,
      index: index,
      activeColor: page.dotActive,
      inactiveColor: page.dotInactive,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(32, 0, 32, _isLast ? 40 : 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              text: page.titleLead,
              children: [
                TextSpan(
                  text: page.titleAccent,
                  style: TextStyle(color: page.accent),
                ),
              ],
            ),
            style: context.t.h1.copyWith(height: 1.18),
          ),
          const SizedBox(height: 14),
          Text(page.bodyText, style: context.t.bodyText.copyWith(height: 1.6)),
          SizedBox(height: _isLast ? 28 : 34),
          if (_isLast) ...[
            Align(alignment: Alignment.centerLeft, child: dots),
            const SizedBox(height: 22),
            AppButton(
              label: "Create your pet's profile",
              variant: AppButtonVariant.start,
              onPressed: onCreate,
            ),
            const SizedBox(height: 16),
            InlineLink(
              prefix: 'Already have an account?',
              action: 'Log in',
              onTap: onLogin,
            ),
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                dots,
                _NextButton(fill: page.buttonFill, onTap: onNext),
              ],
            ),
        ],
      ),
    );
  }
}

/// The 60×60 circular chevron advancing the carousel.
class _NextButton extends StatelessWidget {
  final Color fill;
  final VoidCallback onTap;

  const _NextButton({required this.fill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Next',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: fill.withValues(alpha: 0.6),
                blurRadius: 26,
                spreadRadius: -10,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AppIcon(AppIcons.chevronRight(), size: 22),
        ),
      ),
    );
  }
}
