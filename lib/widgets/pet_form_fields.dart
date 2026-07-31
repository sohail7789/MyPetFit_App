import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../models/pet_info.dart';

/// Validators for pet attributes.
///
/// The old per-screen validators only checked for a non-empty string, so
/// `-5` kg, `0` cm, or `99` months all passed and were persisted.
abstract final class PetValidators {
  static String? name(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  static String? ageYears(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Numbers only';
    if (n < 0 || n > 30) return '0–30';
    return null;
  }

  static String? ageMonths(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Numbers only';
    if (n < 0 || n > 11) return '0–11';
    return null;
  }

  static String? weightKg(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Numbers only';
    if (n <= 0 || n > 200) return '0–200 kg';
    return null;
  }

  static String? heightCm(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Numbers only';
    if (n <= 0 || n > 200) return '0–200 cm';
    return null;
  }
}

/// Holds the controllers and selection state for a pet form.
///
/// Callers own the lifecycle (create in `initState`, `dispose` in `dispose`)
/// and pass it to [PetFormFields]. This is what lets the inline funnel form
/// and the modal sheet share one set of fields and validators.
class PetFormData {
  final nameCtrl = TextEditingController();
  final breedCtrl = TextEditingController();
  final ageYearsCtrl = TextEditingController();
  final ageMonthsCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  PetGender gender = PetGender.male;
  PetSpecies species = PetSpecies.dog;

  PetInfo build() => PetInfo(
        id: 'pet_${DateTime.now().millisecondsSinceEpoch}',
        name: nameCtrl.text.trim(),
        breed: breedCtrl.text.trim(),
        ageYears: int.tryParse(ageYearsCtrl.text.trim()) ?? 0,
        ageMonths: int.tryParse(ageMonthsCtrl.text.trim()) ?? 0,
        gender: gender,
        species: species,
        weightKg: double.tryParse(weightCtrl.text.trim()) ?? 0,
        heightCm: double.tryParse(heightCtrl.text.trim()) ?? 0,
      );

  void dispose() {
    nameCtrl.dispose();
    breedCtrl.dispose();
    ageYearsCtrl.dispose();
    ageMonthsCtrl.dispose();
    weightCtrl.dispose();
    heightCtrl.dispose();
  }
}

/// The shared field stack for creating a pet. Must sit inside a [Form].
class PetFormFields extends StatelessWidget {
  final PetFormData data;

  /// Called when species or gender changes so the parent can rebuild.
  final VoidCallback onChanged;

  /// Invoked when the user submits from the last field's keyboard action.
  final VoidCallback? onSubmit;

  const PetFormFields({
    super.key,
    required this.data,
    required this.onChanged,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: CupertinoSlidingSegmentedControl<PetSpecies>(
            groupValue: data.species,
            thumbColor: AppTheme.interactive(isDark),
            // darkBlueSurface matched the card fill, so the whole control
            // disappeared in dark mode. darkBlueBg gives real separation.
            backgroundColor: isDark
                ? AppTheme.darkBlueBg
                : const Color(0xFFEDEDF0),
            children: {
              for (final sp in PetSpecies.values)
                sp: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    sp.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: data.species == sp
                          ? (isDark ? AppTheme.darkBlueBg : Colors.white)
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
            },
            onValueChanged: (v) {
              if (v == null) return;
              HapticFeedback.selectionClick();
              data.species = v;
              onChanged();
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: data.nameCtrl,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Pet name'),
          validator: PetValidators.name,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: data.breedCtrl,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Breed'),
          validator: PetValidators.name,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: data.ageYearsCtrl,
                textInputAction: TextInputAction.next,
                decoration:
                    const InputDecoration(labelText: 'Age (years)'),
                keyboardType: TextInputType.number,
                validator: PetValidators.ageYears,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                controller: data.ageMonthsCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Months'),
                keyboardType: TextInputType.number,
                validator: PetValidators.ageMonths,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<PetGender>(
          initialValue: data.gender,
          decoration: const InputDecoration(labelText: 'Gender'),
          dropdownColor: AppTheme.surface(isDark),
          borderRadius: BorderRadius.circular(AppRadius.md),
          items: const [
            DropdownMenuItem(value: PetGender.male, child: Text('Male')),
            DropdownMenuItem(
                value: PetGender.female, child: Text('Female')),
          ],
          onChanged: (v) {
            if (v == null) return;
            data.gender = v;
            onChanged();
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: data.weightCtrl,
                textInputAction: TextInputAction.next,
                decoration:
                    const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: PetValidators.weightKg,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                controller: data.heightCtrl,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onSubmit?.call(),
                decoration:
                    const InputDecoration(labelText: 'Height (cm)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: PetValidators.heightCm,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
