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

/// Which flow this form is serving.
///
/// Same reasoning as [PetFormMode]: inside the assessment this is step 2 of
/// 3 and continues to pet details, but from the owner profile it is an
/// editor that saves and returns. The fields are identical, so the form is
/// shared rather than duplicated.
enum OwnerFormMode {
  /// Step 2 of the first-run assessment. Saves, then continues to pet details.
  onboarding,

  /// Editing from the owner profile (design screen 33e). Saves and returns.
  edit,
}

/// Screen 11 — Owner details, and 33e when opened from the owner profile.
class OwnerInfoScreen extends StatefulWidget {
  final OwnerFormMode mode;

  const OwnerInfoScreen({super.key, this.mode = OwnerFormMode.onboarding});

  bool get isEditing => mode == OwnerFormMode.edit;

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

    final email = _email.text.trim();
    if (email.isNotEmpty && !_emailLooksValid(email)) {
      setState(() => _error = 'That email address looks wrong.');
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

    if (widget.isEditing) {
      // backOr, not pop: reached from a deep link or after a stack
      // replacement there is nothing to pop, and go_router throws.
      context.backOr(AppRoutes.ownerProfile);
      return;
    }

    context.push(AppRoutes.petInfo);
  }

  /// Deliberately permissive — this is a contact field, not a login, and a
  /// regex strict enough to be worth arguing about would reject real
  /// addresses. It only catches obvious typos.
  static bool _emailLooksValid(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

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
                    onPressed: () => context.backOr(
                      widget.isEditing
                          ? AppRoutes.ownerProfile
                          : AppRoutes.home,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.isEditing ? 'Edit profile' : 'Owner details',
                    style: AppTheme.h1.copyWith(fontSize: 26, letterSpacing: -1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isEditing
                        ? 'These details go on the report you share with '
                            'your vet.'
                        : 'Step 2 of 3 · so your report can reach you.',
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
                    // Assessment-only: the vet belongs to a pet record, and
                    // editing the owner profile has no single pet in view, so
                    // asking for "the" vet there would be ambiguous.
                    if (!widget.isEditing) ...[
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
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 16, 26, 30),
              child: AppButton(
                label: widget.isEditing ? 'Save changes' : 'Continue',
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
