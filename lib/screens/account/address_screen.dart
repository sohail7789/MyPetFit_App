import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/address.dart';
import '../../providers/address_provider.dart';
import '../../providers/pet_info_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/settings_tile.dart';

/// Screen 33d's editor — add or edit one delivery address.
///
/// [addressId] null means "add"; otherwise the entry with that id is loaded
/// and updated in place.
class AddressScreen extends StatefulWidget {
  final String? addressId;

  const AddressScreen({super.key, this.addressId});

  bool get isEditing => addressId != null;

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _landmark = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();

  /// Field key → message, so each error sits under the field it belongs to
  /// rather than as one banner listing everything that is wrong.
  final Map<String, String> _errors = {};

  AddressLabel _label = AddressLabel.home;
  bool _makeDefault = false;
  bool _saving = false;

  /// Preserved so an edit keeps the entry's identity rather than creating a
  /// duplicate.
  String? _editingId;

  @override
  void initState() {
    super.initState();

    final provider = context.read<AddressProvider>();
    final existing = widget.addressId == null
        ? null
        : provider.byId(widget.addressId!);

    if (existing != null) {
      _editingId = existing.id;
      _label = existing.label;
      _makeDefault = provider.defaultId == existing.id;
      _name.text = existing.fullName;
      _phone.text = existing.phone;
      _line1.text = existing.line1;
      _line2.text = existing.line2;
      _landmark.text = existing.landmark;
      _city.text = existing.city;
      _state.text = existing.state;
      _pincode.text = existing.pincode;
      return;
    }

    // The first address is the default whether or not the switch is on, so
    // show that honestly rather than offering a choice that isn't one.
    _makeDefault = !provider.hasAddress;

    // Seed the recipient from the owner details already captured in the
    // assessment rather than asking twice.
    final owner = context.read<PetInfoProvider>().ownerInfo;
    if (owner != null) {
      _name.text = owner.name;
      _phone.text = owner.contactNumber;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _line1,
      _line2,
      _landmark,
      _city,
      _state,
      _pincode,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Digits only, ignoring spaces and a +91 prefix.
  static String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  bool _validate() {
    final errors = <String, String>{};

    if (_name.text.trim().isEmpty) {
      errors['name'] = 'Who should the courier ask for?';
    }

    final phone = _digits(_phone.text);
    if (phone.isEmpty) {
      errors['phone'] = 'A contact number is required for delivery.';
    } else if (phone.length < 10) {
      errors['phone'] = 'That number looks too short.';
    }

    if (_line1.text.trim().isEmpty) {
      errors['line1'] = 'Add a house or flat number and street.';
    }
    if (_city.text.trim().isEmpty) errors['city'] = 'City is required.';
    if (_state.text.trim().isEmpty) errors['state'] = 'State is required.';

    if (_digits(_pincode.text).length != 6) {
      errors['pincode'] = 'Indian PIN codes are 6 digits.';
    }

    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }

  Future<void> _save() async {
    if (_saving || !_validate()) return;
    setState(() => _saving = true);

    final addresses = context.read<AddressProvider>();
    final pets = context.read<PetInfoProvider>();

    final address = Address(
      id: _editingId ?? 'addr_${DateTime.now().microsecondsSinceEpoch}',
      label: _label,
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      line1: _line1.text.trim(),
      line2: _line2.text.trim(),
      landmark: _landmark.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      pincode: _digits(_pincode.text),
    );

    await addresses.save(address, makeDefault: _makeDefault);

    // Mirror the default onto the owner record so the shared report and any
    // future invoice read the same address without a second lookup.
    final owner = pets.ownerInfo;
    final fallback = addresses.address;
    if (owner != null && fallback != null) {
      pets.setOwnerInfo(owner.copyWith(address: fallback.formatted));
    }

    if (!mounted) return;
    setState(() => _saving = false);
    context.backOr(AppRoutes.addresses);
  }

  void _clearError(String key) {
    if (_errors.containsKey(key)) setState(() => _errors.remove(key));
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = !context.watch<AddressProvider>().hasAddress;

    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: widget.isEditing ? 'Edit address' : 'Add address',
              onBack: () => context.backOr(AppRoutes.addresses),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('Label', style: context.t.overline),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final option in AddressLabel.values)
                        _LabelChip(
                          label: option.display,
                          selected: _label == option,
                          onTap: () => setState(() => _label = option),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _field(
                    key: 'name',
                    label: 'Recipient name',
                    hint: 'Who receives the parcel',
                    controller: _name,
                    action: TextInputAction.next,
                  ),
                  _field(
                    key: 'phone',
                    label: 'Contact number',
                    hint: '+91 00000 00000',
                    controller: _phone,
                    keyboard: TextInputType.phone,
                    action: TextInputAction.next,
                  ),
                  _field(
                    key: 'line1',
                    label: 'Flat / house no. & street',
                    hint: '12B, MG Road',
                    controller: _line1,
                    action: TextInputAction.next,
                  ),
                  _field(
                    key: 'line2',
                    label: 'Area / locality',
                    note: 'optional',
                    hint: 'Koregaon Park',
                    controller: _line2,
                    action: TextInputAction.next,
                  ),
                  _field(
                    key: 'landmark',
                    label: 'Landmark',
                    note: 'optional',
                    hint: 'Near the blue gate',
                    controller: _landmark,
                    action: TextInputAction.next,
                  ),
                  _field(
                    key: 'city',
                    label: 'City',
                    hint: 'Pune',
                    controller: _city,
                    action: TextInputAction.next,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          key: 'state',
                          label: 'State',
                          hint: 'Maharashtra',
                          controller: _state,
                          action: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: _field(
                          key: 'pincode',
                          label: 'PIN code',
                          hint: '411001',
                          controller: _pincode,
                          keyboard: TextInputType.number,
                          action: TextInputAction.done,
                          formatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _DefaultSwitch(
                    value: _makeDefault || isFirst,
                    // The first address saved is the default by definition,
                    // so the switch is locked on rather than pretending to
                    // offer a choice.
                    enabled: !isFirst,
                    onChanged: (v) => setState(() => _makeDefault = v),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: context.c.surface,
                border: Border(top: BorderSide(color: context.c.borderSoft)),
              ),
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
              child: Column(
                children: [
                  AppButton(
                    label: _saving
                        ? 'Saving…'
                        : (widget.isEditing ? 'Save changes' : 'Add address'),
                    height: AppTheme.ctaHeightCompact,
                    onPressed: _saving ? null : _save,
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.outline,
                    height: 48,
                    onPressed: _saving
                        ? null
                        : () => context.backOr(AppRoutes.addresses),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String key,
    required String label,
    required String hint,
    required TextEditingController controller,
    String? note,
    TextInputType? keyboard,
    TextInputAction? action,
    List<TextInputFormatter>? formatters,
  }) {
    final error = _errors[key];

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: label,
            labelNote: note,
            hint: hint,
            controller: controller,
            height: 56,
            keyboardType: keyboard,
            textInputAction: action,
            inputFormatters: formatters,
            // Hands focus to the next field in the form's own traversal
            // order rather than unfocusing. An unfocus closes the keyboard
            // and the next field immediately reopens it, which on iOS is a
            // visible dismiss-and-reopen between every pair of fields.
            // TextField owns a node that outlives its rebuilds, so nothing
            // here needs to hold one.
            onSubmitted: action == TextInputAction.done
                ? null
                : (_) => FocusScope.of(context).nextFocus(),
            onChanged: (_) => _clearError(key),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 5, 4, 0),
              child: Text(
                error,
                style: AppTheme.font(
                  size: 12,
                  weight: FontWeight.w600,
                  color: context.c.dangerText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LabelChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? context.c.tint : context.c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? context.c.actionText : context.c.border,
            ),
          ),
          // Align rather than the Container's own `alignment`: setting that
          // makes a Container expand to its constraints, and inside a Wrap
          // those are the full row width — which stacked the three chips one
          // per line. widthFactor keeps it hugging the label while the text
          // still centres inside the 42px minimum.
          child: Align(
            alignment: Alignment.center,
            widthFactor: 1,
            child: Text(
              label,
              style: AppTheme.font(
                size: 14,
                weight: FontWeight.w700,
                color: selected ? context.c.actionText : context.c.body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaultSwitch extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _DefaultSwitch({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged(!value) : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.c.tintPanel,
            borderRadius: BorderRadius.circular(AppTheme.radiusCardSmall),
            border: Border.all(color: context.c.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  enabled
                      ? 'Set as default delivery address'
                      : 'This will be your default address',
                  style: AppTheme.font(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: context.c.ink,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 24,
                decoration: BoxDecoration(
                  color: value ? context.c.action : context.c.dotInactive,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: context.c.onAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
