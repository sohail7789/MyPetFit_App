import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/pet_info.dart';
import '../../services/sync_reconciler.dart' show kUnknownUpdatedAt;
import '../../providers/auth_provider.dart';
import '../../providers/pet_info_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/photo_slot.dart';
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
  final _vet = TextEditingController();
  final _vetPhone = TextEditingController();

  String? _error;

  /// Held in form state so backing out of an edit doesn't persist the pick.
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    // Re-entering the step (from the back button, or from settings) should
    // show what was entered last time rather than a blank form.
    final owner = context.read<PetInfoProvider>().ownerInfo;
    if (owner != null) {
      _name.text = owner.name;
      _phone.text = owner.contactNumber;
      _vet.text = owner.vetName ?? '';
      _vetPhone.text = owner.vetContact ?? '';
      _photoPath = owner.photoPath;
    }
  }

  /// One node per field, created once and owned here, so Return hands focus
  /// straight along the form. See [AppField] — an unfocus between fields is
  /// what tears the keyboard down and builds it back up.
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _vetFocus = FocusNode();
  final _vetPhoneFocus = FocusNode();

  @override
  void dispose() {
    for (final c in [_name, _phone, _vet, _vetPhone]) {
      c.dispose();
    }
    for (final f in [_nameFocus, _phoneFocus, _vetFocus, _vetPhoneFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  /// The address this account signed in with.
  ///
  /// Not a field on this form. It comes from Firebase Authentication —
  /// [AuthProvider] carries `credential.user.email` from every sign-in path
  /// — and the account is the authority on it, so there is nothing here for
  /// a user to type or correct. Typing it invited two answers to one
  /// question and produced exactly that: an account address and a separately
  /// typed contact address that could disagree.
  ///
  /// Read through the provider rather than `FirebaseAuth.instance` directly
  /// because this screen is widget-tested; see the note on
  /// [AuthProvider.new] about not touching the Firebase singleton merely to
  /// construct state.
  String _authEmail(BuildContext context) =>
      context.read<AuthProvider>().email.trim();

  /// Saves the step, then continues. Previously this screen only navigated —
  /// nothing typed here was ever persisted, so the report card and the
  /// shared PDF had no owner to name.
  Future<void> _continue() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }

    final pets = context.read<PetInfoProvider>();

    // The account address, never anything typed here. When the provider has
    // none — a session restored without one — the stored value is carried
    // through rather than blanked, so an existing record is never damaged by
    // a field this form no longer owns.
    final authEmail = _authEmail(context);
    final email = authEmail.isNotEmpty
        ? authEmail
        : (pets.ownerInfo?.email ?? '');

    await pets.setOwnerInfo(
      OwnerInfo(
        name: name,
        contactNumber: _phone.text.trim(),
        email: email,
        // Address is captured at checkout, not here; preserve anything
        // already saved so continuing past this step never wipes it.
        address: pets.ownerInfo?.address,
        vetName: _vet.text.trim().isEmpty ? null : _vet.text.trim(),
        vetContact: _vetPhone.text.trim().isEmpty
            ? null
            : _vetPhone.text.trim(),
        photoPath: _photoPath,
        // Stamped by the provider, not here — a screen has no business
        // deciding when a record changed. This value is overwritten.
        updatedAt: kUnknownUpdatedAt,
      ),
    );

    if (!mounted) return;

    if (widget.isEditing) {
      // backOr, not pop: reached from a deep link or after a stack
      // replacement there is nothing to pop, and go_router throws.
      context.backOr(AppRoutes.ownerProfile);
      return;
    }

    context.push(AppRoutes.petInfo);
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
                      widget.isEditing
                          ? AppRoutes.ownerProfile
                          : AppRoutes.home,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.isEditing ? 'Edit profile' : 'Owner details',
                    style: context.t.h1.copyWith(
                      fontSize: 26,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isEditing
                        ? 'These details go on the report you share with '
                              'your vet.'
                        : 'Step 2 of 3 · so your report can reach you.',
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
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
                child: Column(
                  children: [
                    // Centred rather than in a card: the owner form has no
                    // artwork above it, so the photo doubles as the header.
                    Center(
                      child: PhotoSlot(
                        photoPath: _photoPath,
                        slot: 'owner',
                        size: 88,
                        onChanged: (path) => setState(() => _photoPath = path),
                      ),
                    ),
                    const SizedBox(height: 18),
                    LabeledField(
                      label: 'Owner name',
                      hint: 'Full name',
                      controller: _name,
                      focusNode: _nameFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _phoneFocus.requestFocus(),
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
                            color: context.c.dangerText,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    LabeledField(
                      label: 'Contact number',
                      hint: '+91 00000 00000',
                      controller: _phone,
                      focusNode: _phoneFocus,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      // Skips the read-only email, which has no node to
                      // receive focus.
                      onSubmitted: (_) => _vetFocus.requestFocus(),
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final email = _authEmail(context);
                        return LabeledField(
                          label: 'Email',
                          labelNote: 'from your account',
                          hint: 'you@email.com',
                          // A value rather than a controller is what makes it
                          // read-only — see LabeledField, which renders text
                          // instead of a TextField when this is set. The
                          // account owns this address; the form does not.
                          readOnlyValue: email.isNotEmpty
                              ? email
                              : 'Not provided',
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: 'Veterinarian name',
                      labelNote: 'optional',
                      hint: 'Dr. name',
                      controller: _vet,
                      focusNode: _vetFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _vetPhoneFocus.requestFocus(),
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: 'Vet contact',
                      labelNote: 'optional',
                      hint: '+91 00000 00000',
                      controller: _vetPhone,
                      focusNode: _vetPhoneFocus,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                    ),
                    // Artwork is assessment-only; the editor is a settings
                    // screen and a mascot there is noise.
                    if (!widget.isEditing) ...[
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
