import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/pet_info.dart';
import '../../services/sync_reconciler.dart' show kUnknownUpdatedAt;
import '../../providers/pet_info_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/photo_slot.dart';

/// Why this screen has modes
/// ------------------------
/// The same form is reached from two places that want different endings.
/// Inside the assessment it is step 3 of 3 and should roll straight into the
/// questions. From My pets it is a profile editor, and pushing someone into
/// 45 questions because they tapped "Add a pet" is the wrong contract — the
/// pet should simply exist, and the assessment should be an invitation on
/// its profile.
enum PetFormMode {
  /// Step 3 of the first-run assessment. Saves, then starts the quiz.
  onboarding,

  /// Adding a pet from My pets. Saves, then opens the new pet's profile.
  add,

  /// Editing an existing pet. Saves, then returns.
  edit,
}

/// Screen 12 — Pet details.
class PetInfoScreen extends StatefulWidget {
  final PetFormMode mode;

  /// Index into [PetInfoProvider.pets] when [mode] is [PetFormMode.edit].
  final int? petIndex;

  const PetInfoScreen({
    super.key,
    this.mode = PetFormMode.onboarding,
    this.petIndex,
  });

  @override
  State<PetInfoScreen> createState() => _PetInfoScreenState();
}

class _PetInfoScreenState extends State<PetInfoScreen> {
  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _years = TextEditingController();
  final _months = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _microchip = TextEditingController();
  String? _gender;
  String? _error;

  /// Where the chosen photo is stored, or null for none. Held in form state
  /// rather than written straight to the provider so cancelling out of an
  /// edit doesn't leave the change behind.
  String? _photoPath;

  /// The pet being edited, if any.
  PetInfo? _editing;

  /// Stable per-form id so a photo chosen before the pet is saved lands in
  /// one file rather than a new one on every pick.
  final String _draftSlot = 'draft-${DateTime.now().microsecondsSinceEpoch}';

  /// The id a pet created by this form gets — minted once, not per submit.
  ///
  /// Same reasoning as [_draftSlot], and it was the same defect. Onboarding
  /// pushes the quiz on top of this screen, so backing out of the first
  /// question returns to *this* State with [_editing] still null: it was set
  /// in initState, before any pet existed. Submitting again therefore built a
  /// pet with a fresh timestamp id, and while [PetInfoProvider.setPetInfo]
  /// replaces the active pet locally — so the app still showed one — the
  /// cloud write is keyed by id, so Firestore gained a second document. The
  /// first was left with no assessments, because the assessment then saved
  /// under the second.
  ///
  /// Minted lazily so a form that only edits never generates one.
  late final String _newPetId = 'pet_${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();

    final pets = context.read<PetInfoProvider>();
    final index = widget.petIndex;

    // In onboarding, re-entering the step should show the pet already
    // captured rather than a blank form.
    final existing = switch (widget.mode) {
      PetFormMode.edit =>
        (index != null && index >= 0 && index < pets.pets.length)
            ? pets.pets[index]
            : null,
      PetFormMode.onboarding => pets.activePet,
      PetFormMode.add => null,
    };

    if (existing == null) return;

    _editing = existing;
    _photoPath = existing.photoPath;
    _name.text = existing.name;
    _breed.text = existing.breed;
    if (existing.ageYears > 0) _years.text = '${existing.ageYears}';
    if (existing.ageMonths > 0) _months.text = '${existing.ageMonths}';
    if (existing.weightKg > 0) {
      _weight.text = _trimZero(existing.weightKg);
    }
    if (existing.heightCm > 0) {
      _height.text = _trimZero(existing.heightCm);
    }
    _microchip.text = existing.microchipNumber ?? '';
    _gender = existing.gender == PetGender.male ? 'Male' : 'Female';
  }

  static String _trimZero(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  @override
  void dispose() {
    for (final c in [
      _name,
      _breed,
      _years,
      _months,
      _weight,
      _height,
      _microchip,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _title => switch (widget.mode) {
    PetFormMode.onboarding => 'Pet details',
    PetFormMode.add => 'Add a pet',
    PetFormMode.edit => 'Edit pet',
  };

  String get _subtitle => switch (widget.mode) {
    PetFormMode.onboarding => 'Step 3 of 3 · this shapes the scoring.',
    PetFormMode.add =>
      'Just the basics. You can take the assessment right after.',
    PetFormMode.edit => 'Update anything that has changed.',
  };

  String get _cta => switch (widget.mode) {
    PetFormMode.onboarding => 'Start the assessment',
    PetFormMode.add => 'Save pet',
    PetFormMode.edit => 'Save changes',
  };

  /// Builds a [PetInfo] from the form. The vet lives on the owner.
  PetInfo _collect() {
    final base = _editing;
    return PetInfo(
      id: base?.id ?? _newPetId,
      name: _name.text.trim(),
      breed: _breed.text.trim(),
      ageYears: int.tryParse(_years.text.trim()) ?? 0,
      ageMonths: int.tryParse(_months.text.trim()) ?? 0,
      gender: _gender == 'Female' ? PetGender.female : PetGender.male,
      species: base?.species ?? PetSpecies.dog,
      weightKg: double.tryParse(_weight.text.trim()) ?? 0,
      heightCm: double.tryParse(_height.text.trim()) ?? 0,
      microchipNumber: _microchip.text.trim().isEmpty
          ? null
          : _microchip.text.trim(),
      photoPath: _photoPath,
      // Stamped by the provider, not here. Overwritten on save.
      updatedAt: kUnknownUpdatedAt,
    );
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = "Please enter your pet's name.");
      return;
    }

    final pets = context.read<PetInfoProvider>();
    final pet = _collect();

    switch (widget.mode) {
      case PetFormMode.onboarding:
        await pets.setPetInfo(pet);

        if (!mounted) return;

        context.push(AppRoutes.quiz);

      case PetFormMode.add:
        if (!pets.canAddPet) {
          setState(
            () => _error =
                'You can manage up to ${PetInfoProvider.maxPets} pets.',
          );
          return;
        }

        await pets.addPet(pet);

        if (!mounted) return;

        context.pushReplacement('${AppRoutes.pets}/${pets.activePetIndex}');

      case PetFormMode.edit:
        final index = widget.petIndex;
        if (index != null) pets.updatePet(index, pet);
        // backOr, not pop: reached from a deep link or after a stack
        // replacement there is nothing to pop, and go_router throws.
        context.backOr(
          index == null ? AppRoutes.pets : AppRoutes.petProfile(index),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
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
                      widget.mode == PetFormMode.onboarding
                          ? AppRoutes.home
                          : AppRoutes.pets,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _title,
                    style: context.t.h1.copyWith(
                      fontSize: 26,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subtitle,
                    style: AppTheme.font(
                      size: 14,
                      color: context.c.body,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 18, 26, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PhotoPrompt(
                      photoPath: _photoPath,
                      // A pet being added has no id yet, so the slot is
                      // stamped once here and reused for the record built in
                      // _collect — otherwise every save would orphan the file.
                      slot: 'pet-${_editing?.id ?? _draftSlot}',
                      onChanged: (path) => setState(() => _photoPath = path),
                    ),
                    const SizedBox(height: 11),
                    LabeledField(
                      label: "Pet's name",
                      hint: 'e.g. Bruno',
                      controller: _name,
                      height: 56,
                      textInputAction: TextInputAction.next,
                      // Focus moves along the form's traversal order; an
                      // unfocus here would close the keyboard and the next
                      // field would immediately reopen it.
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _error!,
                        style: AppTheme.font(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: context.c.dangerText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 11),
                    LabeledField(
                      label: 'Breed',
                      hint: 'e.g. Golden Retriever',
                      controller: _breed,
                      height: 56,
                      textInputAction: TextInputAction.next,
                      // Focus moves along the form's traversal order; an
                      // unfocus here would close the keyboard and the next
                      // field would immediately reopen it.
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Expanded(
                          child: LabeledField(
                            label: 'Age — years',
                            hint: '3',
                            controller: _years,
                            height: 56,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: LabeledField(
                            label: 'Months',
                            hint: '4',
                            controller: _months,
                            height: 56,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 10,
                      ),
                      // Wrap, not Row: "Gender" plus both chips overflow a
                      // narrow screen once the font scale rises.
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Text(
                            'Gender',
                            style: AppTheme.font(
                              size: 13,
                              weight: FontWeight.w600,
                              color: context.c.body,
                            ),
                          ),
                          ChoiceChips(
                            options: const ['Male', 'Female'],
                            selected: _gender,
                            onSelect: (g) => setState(() => _gender = g),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: LabeledField(
                            label: 'Weight (kg)',
                            hint: '24',
                            controller: _weight,
                            height: 56,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: LabeledField(
                            label: 'Height (cm)',
                            hint: '56',
                            controller: _height,
                            height: 56,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    LabeledField(
                      label: 'Microchip / tag number',
                      labelNote: 'optional',
                      hint: '000 000 000 000',
                      controller: _microchip,
                      height: 56,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 16, 26, 30),
              child: Column(
                children: [
                  AppButton(
                    label: _cta,
                    variant: widget.mode == PetFormMode.onboarding
                        ? AppButtonVariant.start
                        : AppButtonVariant.action,
                    height: AppTheme.ctaHeightCompact,
                    onPressed: _submit,
                  ),
                  if (widget.mode == PetFormMode.onboarding) ...[
                    const SizedBox(height: 12),
                    Text(
                      '45 questions · 9 categories · about 6 minutes',
                      textAlign: TextAlign.center,
                      style: AppTheme.font(size: 12, color: context.c.muted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The circular photo well plus its supporting copy.
class _PhotoPrompt extends StatelessWidget {
  final String? photoPath;
  final String slot;
  final ValueChanged<String?> onChanged;

  const _PhotoPrompt({
    required this.photoPath,
    required this.slot,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null;

    return AppCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [context.c.surface, context.c.surfaceRaised],
      ),
      child: Row(
        children: [
          PhotoSlot(photoPath: photoPath, slot: slot, onChanged: onChanged),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPhoto ? "Your pet's photo" : "Add your pet's photo",
                  style: AppTheme.font(
                    size: 14.5,
                    weight: FontWeight.w800,
                    color: context.c.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPhoto
                      ? 'Tap the photo to change or remove it.'
                      : 'Tap the circle to take one or pick from your '
                            'library. It shows on the report card and helps '
                            'your vet identify records.',
                  style: AppTheme.font(
                    size: 12.5,
                    color: context.c.body,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
