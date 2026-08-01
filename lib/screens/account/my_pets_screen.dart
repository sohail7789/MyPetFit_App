import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/pet_info.dart';
import '../../providers/pet_info_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/design_image.dart';
import '../../widgets/paw_mark.dart';
import '../../widgets/settings_tile.dart';

/// Screen 33 — My pets.
class MyPetsScreen extends StatelessWidget {
  const MyPetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetInfoProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(title: 'My pets', onBack: () => context.backOr(AppRoutes.account)),
            Expanded(
              child: pets.pets.isEmpty
                  ? _Empty(onAdd: () => context.push(AppRoutes.petInfo))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                      children: [
                        for (var i = 0; i < pets.pets.length; i++) ...[
                          _PetCard(
                            pet: pets.pets[i],
                            isActive: i == pets.activePetIndex,
                            onEdit: () => context.push(AppRoutes.editPet),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (pets.canAddPet)
                          AppButton(
                            label: 'Add another pet',
                            variant: AppButtonVariant.outline,
                            height: 52,
                            onPressed: () => context.push(AppRoutes.petInfo),
                          )
                        else
                          Text(
                            'You can manage up to '
                            '${PetInfoProvider.maxPets} pets.',
                            textAlign: TextAlign.center,
                            style: AppTheme.font(
                              size: 12.5,
                              color: AppTheme.muted,
                            ),
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

class _Empty extends StatelessWidget {
  final VoidCallback onAdd;

  const _Empty({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DesignImage(AppAssets.emoQuestion, width: 120, height: 120),
            const SizedBox(height: 14),
            Text('No pets yet', style: AppTheme.h2),
            const SizedBox(height: 10),
            Text(
              "Add your pet's profile so the assessment and recommendations "
              'can be tailored to them.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyText,
            ),
            const SizedBox(height: 22),
            AppButton(label: 'Add a pet', onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetInfo pet;
  final bool isActive;
  final VoidCallback onEdit;

  const _PetCard({
    required this.pet,
    required this.isActive,
    required this.onEdit,
  });

  String get _meta {
    final parts = <String>[
      if (pet.breed.trim().isNotEmpty) pet.breed,
      pet.gender == PetGender.male ? 'Male' : 'Female',
      if (pet.ageYears > 0 || pet.ageMonths > 0)
        '${pet.ageYears} y ${pet.ageMonths} m',
      if (pet.weightKg > 0) '${pet.weightKg.toStringAsFixed(0)} kg',
    ];
    return parts.isEmpty ? 'Profile incomplete' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onEdit,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F1F9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const PawMark(
              size: 26,
              color: AppTheme.action,
              opacity: 0.4,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        pet.name.trim().isEmpty ? 'Unnamed pet' : pet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.font(
                          size: 16,
                          weight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.tint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Active',
                          style: AppTheme.font(
                            size: 10,
                            weight: FontWeight.w800,
                            color: AppTheme.action,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(size: 13, color: AppTheme.body),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Color(0xFFB0AEC2),
          ),
        ],
      ),
    );
  }
}
