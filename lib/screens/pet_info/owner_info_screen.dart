import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/design_image.dart';
import '../../widgets/labeled_field.dart';

/// Screen 11 — Owner details.
class OwnerInfoScreen extends StatefulWidget {
  const OwnerInfoScreen({super.key});

  @override
  State<OwnerInfoScreen> createState() => _OwnerInfoScreenState();
}

class _OwnerInfoScreenState extends State<OwnerInfoScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _vet = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _vet]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    size: 44,
                    semanticLabel: 'Back',
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Owner details',
                    style: AppTheme.h1.copyWith(fontSize: 26, letterSpacing: -1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Step 2 of 3 · so your report can reach you.',
                    style: AppTheme.font(
                      size: 14,
                      color: AppTheme.body,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
                child: Column(
                  children: [
                    LabeledField(
                      label: 'Owner name',
                      hint: 'Full name',
                      controller: _name,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: 'Contact number',
                      hint: '+91 00000 00000',
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: 'Email',
                      hint: 'you@email.com',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: 'Veterinarian name & contact',
                      labelNote: 'optional',
                      hint: 'Dr. name, phone',
                      controller: _vet,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 6),
                    const DesignImage(
                      AppAssets.ownerDetails,
                      width: 120,
                      shadow: true,
                      semanticLabel: 'Waving puppy',
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 16, 26, 30),
              child: AppButton(
                label: 'Continue',
                height: AppTheme.ctaHeightCompact,
                onPressed: () => context.push(AppRoutes.petInfo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
