import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../providers/pet_info_provider.dart';
import 'pet_form_fields.dart';

/// The canonical "Add pet" bottom sheet, shared by the Home dashboard and
/// the Account screen. Field layout and validation live in [PetFormFields]
/// so this sheet and the inline funnel form can never drift apart.
///
/// Pure UI — the only state mutation is [PetInfoProvider.addPet].
Future<void> showAddPetSheet(BuildContext context, PetInfoProvider provider) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _AddPetSheetBody(provider: provider),
  );
}

class _AddPetSheetBody extends StatefulWidget {
  final PetInfoProvider provider;

  const _AddPetSheetBody({required this.provider});

  @override
  State<_AddPetSheetBody> createState() => _AddPetSheetBodyState();
}

class _AddPetSheetBodyState extends State<_AddPetSheetBody> {
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
    widget.provider.addPet(_data.build());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.xxl + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: SheetHandle(isDark: isDark)),
              const SizedBox(height: AppSpacing.lg),
              Text('Add pet', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tell us a little about your companion.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              PetFormFields(
                data: _data,
                onChanged: () => setState(() {}),
                onSubmit: _submit,
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Add pet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Theme-aware drag handle for modal sheets. A fixed grey.shade300 handle
/// was invisible against the dark sheet surface.
class SheetHandle extends StatelessWidget {
  final bool isDark;
  const SheetHandle({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.mutedText(isDark).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
