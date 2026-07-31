import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_info_provider.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _agreed = false;
  final TextEditingController _signatureController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Prefill the signature with the signed-in user's full name so most
    // users don't have to retype it. They can still edit before agreeing.
    final auth = context.read<AuthProvider>();
    if (auth.displayName.isNotEmpty) {
      _signatureController.text = auth.displayName;
    }
    // If the user already consented (returning to this screen via deep-link
    // or back-nav), skip forward instead of forcing them to re-sign.
    final pet = context.read<PetInfoProvider>();
    if (pet.consentGiven) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pushReplacement(AppRoutes.ownerInfo);
      });
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _agreed && _signatureController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final today =
        '${months[now.month - 1]} ${now.day.toString().padLeft(2, '0')}, ${now.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consent & Data Usage'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    'I, the undersigned, voluntarily consent to the collection and use of the information provided in this questionnaire for the purpose of assessing, monitoring, and improving the overall fitness, health, and wellness of my pet through the MyPetFit program. I understand that participation is intended solely for the betterment of pet health and wellbeing.\n\n'
                    'I acknowledge and agree that the data collected may be securely stored and used in an anonymized and aggregated manner for veterinary and clinical research, health and wellness analytics, and the development or improvement of products and services related to companion animal care. This information may be used across scientific, academic, educational, and commercial platforms to advance knowledge in pet health, disease prevention, longevity, and quality-of-life enhancement.\n\n'
                    'I understand that my pet\'s identity and personal information will remain confidential and will not be publicly disclosed. By signing this form, I grant permission for my pet\'s health and lifestyle data to be used as described above without further notice, review, or financial compensation.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.heading(isDark),
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              CheckboxListTile(
                value: _agreed,
                onChanged: (value) {
                  setState(() {
                    _agreed = value ?? false;
                  });
                },
                title: Text(
                  'I agree to the terms above',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                activeColor: AppTheme.interactive(isDark),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _signatureController,
                decoration: const InputDecoration(
                  labelText: 'Signature',
                  hintText: 'Type your full name',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Date: $today',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText(isDark),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              ElevatedButton(
                onPressed: _canContinue
                    ? () {
                        context.read<PetInfoProvider>().giveConsent(
                              signatureName:
                                  _signatureController.text.trim(),
                            );
                        context.push(AppRoutes.ownerInfo);
                      }
                    : null,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
