import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/pet_info.dart';
import '../../providers/pet_info_provider.dart';
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

  String? _error;

  @override
  void initState() {
    super.initState();
    // Re-entering the step (from the back button, or from settings) should
    // show what was entered last time rather than a blank form.
    final owner = context.read<PetInfoProvider>().ownerInfo;
    if (owner != null) {
      _name.text = owner.name;
      _phone.text = owner.contactNumber;
      _email.text = owner.email;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _vet]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Saves the step, then continues. Previously this screen only navigated —
  /// nothing typed here was ever persisted, so the report card and the
  /// shared PDF had no owner to name.
  void _continue() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }

    context.read<PetInfoProvider>().setOwnerInfo(
          OwnerInfo(
            name: name,
            contactNumber: _phone.text.trim(),
            email: _email.text.trim(),
            // Address is captured at checkout, not here; preserve anything
            // already saved so continuing past this step never wipes it.
            address: context.read<PetInfoProvider>().ownerInfo?.address,
          ),
        );

    // The vet field is free text ("Dr. name, phone") and belongs to the pet
    // record, so it is stored against the active pet when there is one.
    final vet = _vet.text.trim();
    final pets = context.read<PetInfoProvider>();
    if (vet.isNotEmpty && pets.activePet != null) {
      pets.updatePet(
        pets.activePetIndex,
        pets.activePet!.copyWith(vetName: vet),
      );
    }

    context.push(AppRoutes.petInfo);
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
                    onPressed: () => context.backOr(AppRoutes.home),
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
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _error!,
                          style: AppTheme.font(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: AppTheme.danger,
                          ),
                        ),
                      ),
                    ],
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
                onPressed: _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
