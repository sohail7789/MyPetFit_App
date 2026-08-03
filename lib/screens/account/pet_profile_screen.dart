import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/pet_info.dart';
import '../../models/score_band.dart';
import '../../providers/pet_info_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/paw_mark.dart';
import '../../widgets/settings_tile.dart';

/// A saved pet's profile.
///
/// This is where "Add a pet" lands. The assessment is offered here as a
/// choice rather than forced immediately after the form, so adding a second
/// pet doesn't mean committing to 45 questions on the spot.
class PetProfileScreen extends StatelessWidget {
  final int petIndex;

  const PetProfileScreen({super.key, required this.petIndex});

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetInfoProvider>();

    // Deleting the pet, or arriving on a stale index after a reinstall,
    // leaves nothing to show — go back rather than render a broken screen.
    if (petIndex < 0 || petIndex >= pets.pets.length) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(
                title: 'Pet',
                onBack: () => context.backOr(AppRoutes.pets),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'This pet is no longer in your list.',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pet = pets.pets[petIndex];
    final isActive = petIndex == pets.activePetIndex;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Edit sits in the header, matching the design and the owner
            // profile beside it.
            ScreenHeader(
              title: pet.name.trim().isEmpty ? 'Pet' : pet.name.trim(),
              onBack: () => context.backOr(AppRoutes.pets),
              trailing: _HeaderAction(
                label: 'Edit',
                onTap: () => context.push(AppRoutes.petEdit(petIndex)),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                children: [
                  _Header(pet: pet, isActive: isActive),
                  const SizedBox(height: 14),
                  _ScoreChip(petId: pet.id),
                  const SizedBox(height: 18),
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Column(
                      children: [
                        _DetailRow(label: 'Breed', value: pet.breed),
                        _DetailRow(label: 'Age', value: pet.ageDisplay),
                        _DetailRow(
                          label: 'Sex',
                          value: pet.gender == PetGender.male
                              ? 'Male'
                              : 'Female',
                        ),
                        _DetailRow(
                          label: 'Weight',
                          value: pet.weightKg > 0
                              ? '${pet.weightKg.toStringAsFixed(1)} kg'
                              : '',
                        ),
                        _DetailRow(
                          label: 'Height',
                          value: pet.heightCm > 0
                              ? '${pet.heightCm.toStringAsFixed(0)} cm'
                              : '',
                        ),
                        _DetailRow(
                          label: 'Microchip',
                          value: pet.microchipNumber ?? '',
                        ),
                        _DetailRow(
                          label: 'Last assessed',
                          value: _lastAssessed(context, pet.id),
                          last: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _AssessmentCard(pet: pet),
                  const SizedBox(height: 14),
                  AppButton(
                    label: 'Report history',
                    variant: AppButtonVariant.outline,
                    height: 52,
                    onPressed: () => context.push(AppRoutes.reportHistory),
                  ),
                  if (!isActive) ...[
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Make this the active pet',
                      variant: AppButtonVariant.tinted,
                      height: 52,
                      onPressed: () =>
                          context.read<PetInfoProvider>().setActivePet(petIndex),
                    ),
                  ],
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Remove pet',
                    variant: AppButtonVariant.outline,
                    height: 52,
                    onPressed: () => _confirmRemove(context, pet),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// When this pet was last assessed. Scoped by id rather than reading the
  /// bound result, because this screen can show a pet that isn't active.
  static String _lastAssessed(BuildContext context, String petId) {
    final result = context.watch<QuizProvider>().resultFor(petId);
    if (result == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = result.completedAt;
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _confirmRemove(BuildContext context, PetInfo pet) async {
    final name = pet.name.trim().isEmpty ? 'this pet' : pet.name.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        title: Text('Remove $name?', style: AppTheme.h3),
        content: Text(
          "Their profile and report cards are deleted from this device. "
          "Your other pets are not affected.",
          style: AppTheme.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: AppTheme.font(
                size: 14,
                weight: FontWeight.w700,
                color: AppTheme.body,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Remove',
              style: AppTheme.font(
                size: 14,
                weight: FontWeight.w700,
                color: AppTheme.danger,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    // Reports are keyed by pet id, so they go with the pet — otherwise they
    // would sit in storage against an id nothing points at.
    context.read<QuizProvider>().clearResultsFor(pet.id);
    context.read<PetInfoProvider>().removePet(petIndex);
    context.backOr(AppRoutes.pets);
  }
}

/// The design's header-level "Edit" link.
class _HeaderAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(
            label,
            style: AppTheme.font(
              size: 14,
              weight: FontWeight.w700,
              color: AppTheme.action,
            ),
          ),
        ),
      ),
    );
  }
}

/// "FITNESS SCORE 72 · GOOD" — the band strip the design shows under the
/// pet's name. Hidden until there is a score to show.
class _ScoreChip extends StatelessWidget {
  final String petId;

  const _ScoreChip({required this.petId});

  @override
  Widget build(BuildContext context) {
    final result = context.watch<QuizProvider>().resultFor(petId);
    if (result == null) return const SizedBox.shrink();

    final band = result.category;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: band.bandTint,
        borderRadius: BorderRadius.circular(AppTheme.radiusCardSmall),
        border: Border.all(color: band.bandLine),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(
            'FITNESS SCORE',
            style: AppTheme.overline.copyWith(color: AppTheme.muted),
          ),
          Text(
            '${result.percentageScore}',
            style: AppTheme.font(
              size: 16,
              weight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          Text(
            '· ${band.label.toUpperCase()}',
            style: AppTheme.font(
              size: 12,
              weight: FontWeight.w800,
              color: band.bandColor,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final PetInfo pet;
  final bool isActive;

  const _Header({required this.pet, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFF4F1F9),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const PawMark(
            size: 32,
            color: AppTheme.action,
            opacity: 0.4,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pet.name.trim().isEmpty ? 'Unnamed pet' : pet.name.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.h2,
              ),
              const SizedBox(height: 4),
              Text(
                pet.breed.trim().isEmpty
                    ? pet.species.label
                    : '${pet.species.label} · ${pet.breed.trim()}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.font(size: 13.5, color: AppTheme.body),
              ),
              if (isActive) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.tint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ACTIVE PET',
                    style: AppTheme.font(
                      size: 10,
                      weight: FontWeight.w800,
                      color: AppTheme.action,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The assessment invitation — the thing that replaces being dumped into the
/// questionnaire straight after saving.
class _AssessmentCard extends StatelessWidget {
  final PetInfo pet;

  const _AssessmentCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    final result = context.watch<QuizProvider>().resultFor(pet.id);
    final name = pet.name.trim().isEmpty ? 'this pet' : pet.name.trim();

    return AppCard(
      background: const Color(0xFFFCFBFD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            result == null ? 'No assessment yet' : 'Fitness assessment',
            style: AppTheme.font(
              size: 15,
              weight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            result == null
                ? 'Take the 45-question assessment to get $name a fitness '
                    'score and matched recommendations. About 6 minutes.'
                : 'Last score ${result.percentageScore}% · '
                    '${result.category.label}. Retake it to see how $name is '
                    'tracking.',
            style: AppTheme.font(
              size: 13,
              color: AppTheme.bodyStrong,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: result == null
                ? 'Start the assessment'
                : 'Retake the assessment',
            variant: AppButtonVariant.start,
            height: 52,
            onPressed: () {
              final pets = context.read<PetInfoProvider>();
              final index = pets.pets.indexWhere((p) => p.id == pet.id);
              // The quiz scores whichever pet is active, so make this one
              // active before starting it.
              if (index >= 0) pets.setActivePet(index);
              context.read<QuizProvider>().reset();
              context.push(AppRoutes.quiz);
            },
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _DetailRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: last
          ? null
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderSoft),
              ),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.font(size: 13.5, color: AppTheme.muted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value.trim().isEmpty ? 'Not set' : value.trim(),
              textAlign: TextAlign.right,
              style: AppTheme.font(
                size: 13.5,
                weight: FontWeight.w700,
                color: value.trim().isEmpty ? AppTheme.muted : AppTheme.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
