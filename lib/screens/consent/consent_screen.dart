import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
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
  const ConsentScreen({super.key});

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
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.tint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.description_outlined,
                      size: 22,
                      color: AppTheme.action,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consent & Use of Data',
                          style: AppTheme.h3.copyWith(
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
                            color: AppTheme.muted,
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
                  color: const Color(0xFFFBFAFD),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(color: AppTheme.border),
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
                              color: AppTheme.bodyStrong,
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
                                  ? AppTheme.action
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(7),
                              border: _agreed
                                  ? null
                                  : Border.all(
                                      color: const Color(0xFFC9C6D9),
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
                              color: AppTheme.bodyStrong,
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
                          background: AppTheme.tintSoft,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Agree & Continue',
                    height: AppTheme.ctaHeightCompact,
                    onPressed:
                        _ready ? () => context.push(AppRoutes.ownerInfo) : null,
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
