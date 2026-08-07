import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/pet_info_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/labeled_field.dart';

/// Copy of the consent form, verbatim from the design.
const _consentParagraphs = <String>[
  'I, the undersigned, voluntarily consent to the collection and use of the '
      'information provided in this questionnaire for the purpose of assessing, '
      'monitoring, and improving the overall fitness, health, and wellness of my '
      'pet through the MyPetFit program. I understand that participation is '
      'intended solely for the betterment of pet health and wellbeing.',
  'I acknowledge and agree that the data collected may be securely stored and '
      'used in an anonymized and aggregated manner for veterinary and clinical '
      'research, health and wellness analytics, and the development or '
      'improvement of products and services related to companion animal care. '
      'This information may be used across scientific, academic, educational, '
      'and commercial platforms to advance knowledge in pet health, disease '
      'prevention, longevity, and quality-of-life enhancement.',
  'I understand that my pet’s identity and personal information will remain '
      'confidential and will not be publicly disclosed. By signing this form, I '
      'grant permission for my pet’s health and lifestyle data to be used as '
      'described above without further notice, review, or financial '
      'compensation.',
];

/// Screen 10 — Consent & Use of Data.
///
/// Continue unlocks only once the box is ticked *and* a signature is typed,
/// matching the design's `consentReady` rule.
class ConsentScreen extends StatefulWidget {
  /// Where to continue once consent is signed, supplied by the router's
  /// gate — the route that was blocked, or the next step of the first run.
  final String? next;

  const ConsentScreen({super.key, this.next});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final _signature = TextEditingController();
  bool _agreed = false;

  @override
  void dispose() {
    _signature.dispose();
    super.dispose();
  }

  bool get _ready => _agreed && _signature.text.trim().length > 1;

  /// Records the signed consent, then resumes whatever was gated.
  ///
  /// Awaited before navigating so the decision is on disk before the screen
  /// is left. The provider owns persistence and the cloud write — see
  /// [PetInfoProvider.giveConsent]. No routing decision is made here: the
  /// destination came from the router's gate.
  ///
  /// `go`, not `push` — the gate replaced the location on the way in, and a
  /// form that has just been signed is not somewhere Back should return to.
  Future<void> _agreeAndContinue(BuildContext context) async {
    await context.read<PetInfoProvider>().giveConsent(
          signatureName: _signature.text,
        );
    if (!context.mounted) return;
    context.go(_destination);
  }

  /// The gated route to resume, defaulting to the first-run next step.
  ///
  /// Only in-app paths are honoured. The value is router-supplied today, but
  /// it arrives as a query parameter, and a destination read from a URL is
  /// not something to hand to the navigator unchecked.
  String get _destination {
    final next = widget.next;
    if (next != null && next.startsWith('/') && !next.startsWith('//')) {
      return next;
    }
    return AppRoutes.petInfo;
  }

  String get _today {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    return '$day ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 16),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    semanticLabel: 'Back',
                    onPressed: () => context.backOr(AppRoutes.home),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consent & Use of Data',
                          style: context.t.h3.copyWith(
                            fontSize: 22,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Step 1 of 3 · required',
                          style: AppTheme.font(
                            size: 13,
                            weight: FontWeight.w600,
                            color: context.c.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable consent body
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.c.surfaceLow,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(color: context.c.border),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < _consentParagraphs.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                i == _consentParagraphs.length - 1 ? 0 : 12,
                          ),
                          child: Text(
                            _consentParagraphs[i],
                            style: AppTheme.font(
                              size: 13,
                              color: context.c.bodyStrong,
                              height: 1.7,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Agreement, signature and CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 16, 26, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _agreed = !_agreed),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _agreed
                                  ? context.c.action
                                  : context.c.surface,
                              borderRadius: BorderRadius.circular(7),
                              border: _agreed
                                  ? null
                                  : Border.all(
                                      color: context.c.borderField,
                                      width: 1.5,
                                    ),
                            ),
                            alignment: Alignment.center,
                            child: _agreed
                                ? AppIcon(AppIcons.check(), size: 13)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'I have read and agree to the consent above.',
                            style: AppTheme.font(
                              size: 13,
                              color: context.c.bodyStrong,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: LabeledField(
                          label: 'Signature',
                          hint: 'Type your full name',
                          controller: _signature,
                          height: 52,
                          radius: 14,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 126,
                        child: LabeledField(
                          label: 'Date',
                          readOnlyValue: _today,
                          height: 52,
                          radius: 14,
                          background: context.c.tintSoft,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Agree & Continue',
                    height: AppTheme.ctaHeightCompact,
                    // Record it, then move on. This only navigated, so
                    // consent was never actually given: the user finished the
                    // assessment with the flag still false — nothing re-checks
                    // the gates once you are past an entry route — and was
                    // sent back here on every later sign-in.
                    onPressed: _ready ? () => _agreeAndContinue(context) : null,
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
