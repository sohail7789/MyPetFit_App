import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/pet_info.dart';
import '../../providers/pet_info_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/paw_mark.dart';

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

  /// The pet being edited, if any.
  PetInfo? _editing;

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

  static String _trimZero(double value) =>
      value == value.roundToDouble()
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

  /// Builds a [PetInfo] from the form, keeping fields this screen doesn't
  /// collect (the photo) when editing. The vet lives on the owner.
  PetInfo _collect() {
    final base = _editing;
    return PetInfo(
      id: base?.id ??
          'pet_${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      breed: _breed.text.trim(),
      ageYears: int.tryParse(_years.text.trim()) ?? 0,
      ageMonths: int.tryParse(_months.text.trim()) ?? 0,
      gender: _gender == 'Female' ? PetGender.female : PetGender.male,
      species: base?.species ?? PetSpecies.dog,
      weightKg: double.tryParse(_weight.text.trim()) ?? 0,
      heightCm: double.tryParse(_height.text.trim()) ?? 0,
      microchipNumber:
          _microchip.text.trim().isEmpty ? null : _microchip.text.trim(),
      photoPath: base?.photoPath,
    );
  }

  void _submit() {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = "Please enter your pet's name.");
      return;
    }

    final pets = context.read<PetInfoProvider>();
    final pet = _collect();

    switch (widget.mode) {
      case PetFormMode.onboarding:
        // setPetInfo replaces the active pet, or creates the first one.
        pets.setPetInfo(pet);
        context.push(AppRoutes.quiz);

      case PetFormMode.add:
        if (!pets.canAddPet) {
          setState(() => _error =
              'You can manage up to ${PetInfoProvider.maxPets} pets.');
          return;
        }
        pets.addPet(pet);
        // addPet makes the new pet active, so its profile is the one at the
        // current active index. Replace rather than push: backing out of the
        // profile should land on My pets, not the form that created it.
        context.pushReplacement(
          '${AppRoutes.pets}/${pets.activePetIndex}',
        );

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
                      widget.mode == PetFormMode.onboarding
                          ? AppRoutes.home
                          : AppRoutes.pets,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _title,
                    style:
                        AppTheme.h1.copyWith(fontSize: 26, letterSpacing: -1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subtitle,
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
                padding: const EdgeInsets.fromLTRB(26, 18, 26, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _PhotoPrompt(),
                    const SizedBox(height: 11),
                    LabeledField(
                      label: "Pet's name",
                      hint: 'e.g. Bruno',
                      controller: _name,
                      height: 56,
                      textInputAction: TextInputAction.next,
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
                          color: AppTheme.danger,
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
                              color: AppTheme.body,
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
                      style: AppTheme.font(size: 12, color: AppTheme.muted),
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

/// The dashed-ring photo slot. Picking an image is not wired up yet — there is
/// no image-picker dependency in the project — so it renders the prompt state.
class _PhotoPrompt extends StatelessWidget {
  const _PhotoPrompt();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF4F1F9)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.tint.withValues(alpha: 0.7),
                    ),
                    child: const Center(
                      child: PawMark(
                        size: 38,
                        color: AppTheme.action,
                        opacity: 0.3,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppTheme.action,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surface, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.ink.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: -4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Add your pet's photo",
                  style: AppTheme.font(
                    size: 14.5,
                    weight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap the circle or drop an image. It shows on the report card '
                  'and helps your vet identify records.',
                  style: AppTheme.font(
                    size: 12.5,
                    color: AppTheme.body,
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
