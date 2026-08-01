import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/paw_mark.dart';

/// Screen 12 — Pet details.
class PetInfoScreen extends StatefulWidget {
  const PetInfoScreen({super.key});

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
                    'Pet details',
                    style:
                        AppTheme.h1.copyWith(fontSize: 26, letterSpacing: -1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Step 3 of 3 · this shapes the scoring.',
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
                    ),
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
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              'Gender',
                              style: AppTheme.font(
                                size: 13,
                                weight: FontWeight.w600,
                                color: AppTheme.body,
                              ),
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
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 16, 26, 30),
              child: Column(
                children: [
                  AppButton(
                    label: 'Start the assessment',
                    variant: AppButtonVariant.start,
                    height: AppTheme.ctaHeightCompact,
                    onPressed: () => context.push(AppRoutes.quiz),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '45 questions · 9 categories · about 6 minutes',
                    style: AppTheme.font(size: 12, color: AppTheme.muted),
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
