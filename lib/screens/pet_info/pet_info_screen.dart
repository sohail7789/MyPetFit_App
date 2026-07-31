import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/pet_info.dart';
import '../../providers/pet_info_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/floating_paws_background.dart';
import '../../widgets/pet_form_fields.dart';
import '../../widgets/primary_button.dart';

/// Step 2 of the funnel: pet profile(s). The owner can add multiple pets.
class PetInfoScreen extends StatefulWidget {
  const PetInfoScreen({super.key});

  @override
  State<PetInfoScreen> createState() => _PetInfoScreenState();
}

class _PetInfoScreenState extends State<PetInfoScreen> {
  bool _showAddForm = false;

  void _confirmRemove(PetInfoProvider provider, int index) {
    final petName = provider.pets[index].name;
    HapticFeedback.mediumImpact();
    // Removal used to fire immediately with no confirmation — the only
    // destructive action in the app without one.
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('Remove $petName?'),
        message: const Text('This can\'t be undone.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              provider.removePet(index);
              Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<PetInfoProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pet Profiles')),
      body: FloatingPawsBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.tint(
                            isDark, AppTheme.secondary, AppTheme.softPeach),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.pets_rounded,
                        color: isDark
                            ? AppTheme.accentPink
                            : AppTheme.secondary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pet profiles',
                              style: theme.textTheme.headlineSmall),
                          const SizedBox(height: 2),
                          Text(
                            'Add up to ${PetInfoProvider.maxPets} pets · ${provider.petCount} added',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.section),

                // Existing pet cards
                for (int i = 0; i < provider.pets.length; i++) ...[
                  _PetSummaryCard(
                    pet: provider.pets[i],
                    index: i + 1,
                    isDark: isDark,
                    onRemove: provider.petCount > 1
                        ? () => _confirmRemove(provider, i)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Add-pet form, or the button that reveals it
                if (provider.pets.isEmpty || _showAddForm)
                  _InlinePetForm(
                    petNumber: provider.petCount + 1,
                    onSubmit: (pet) {
                      provider.addPet(pet);
                      setState(() => _showAddForm = false);
                    },
                    onCancel: provider.pets.isNotEmpty
                        ? () => setState(() => _showAddForm = false)
                        : null,
                  )
                else if (provider.canAddPet)
                  OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showAddForm = true);
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add another pet'),
                  ),

                const SizedBox(height: AppSpacing.section),

                // Proceed
                if (provider.pets.isNotEmpty)
                  PrimaryButton(
                    label: 'Start Assessment',
                    onPressed: () {
                      context.read<QuizProvider>().reset();
                      context.push(AppRoutes.quiz);
                    },
                  ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetSummaryCard extends StatelessWidget {
  final PetInfo pet;
  final int index;
  final bool isDark;
  final VoidCallback? onRemove;

  const _PetSummaryCard({
    required this.pet,
    required this.index,
    required this.isDark,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkBlueBg
                    : AppTheme.lightAzure,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                pet.species.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pet.breed} · ${pet.ageDisplay} · ${pet.weightKg} kg',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppTheme.mutedText(isDark),
                tooltip: 'Remove ${pet.name}',
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}

/// Inline variant of the pet form used inside the onboarding funnel.
/// Shares its fields and validators with the modal sheet via
/// [PetFormFields] / [PetFormData].
class _InlinePetForm extends StatefulWidget {
  final ValueChanged<PetInfo> onSubmit;
  final VoidCallback? onCancel;
  final int petNumber;

  const _InlinePetForm({
    required this.onSubmit,
    required this.petNumber,
    this.onCancel,
  });

  @override
  State<_InlinePetForm> createState() => _InlinePetFormState();
}

class _InlinePetFormState extends State<_InlinePetForm> {
  final _formKey = GlobalKey<FormState>();
  final _data = PetFormData();

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.selectionClick();
    widget.onSubmit(_data.build());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Pet ${widget.petNumber}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (widget.onCancel != null)
                    TextButton(
                      onPressed: widget.onCancel,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Cancel'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              PetFormFields(
                data: _data,
                onChanged: () => setState(() {}),
                onSubmit: _submit,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text('Add pet ${widget.petNumber}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
