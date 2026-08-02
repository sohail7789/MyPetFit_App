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

/// Delivery address form.
///
/// Reached from the checkout address card and from account settings; both
/// edit the same saved address, so there is one place a wrong pincode gets
/// fixed.
class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

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

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final saved = context.read<AddressProvider>().address;
    if (saved != null) {
      _name.text = saved.fullName;
      _phone.text = saved.phone;
      _line1.text = saved.line1;
      _line2.text = saved.line2;
      _landmark.text = saved.landmark;
      _city.text = saved.city;
      _state.text = saved.state;
      _pincode.text = saved.pincode;
      return;
    }

    // First time through, seed the name and phone from the owner details
    // already captured in the assessment rather than asking twice.
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
  static String _digits(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

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

    final pin = _digits(_pincode.text);
    if (pin.length != 6) {
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

    final address = Address(
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      line1: _line1.text.trim(),
      line2: _line2.text.trim(),
      landmark: _landmark.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      pincode: _digits(_pincode.text),
    );

    // Both providers are resolved before the await so nothing reaches for a
    // context that may have been unmounted by the time the write lands.
    final addresses = context.read<AddressProvider>();
    final pets = context.read<PetInfoProvider>();

    await addresses.save(address);

    // Mirror onto the owner record so the shared report and any future
    // invoice have the same address without a second lookup.
    final owner = pets.ownerInfo;
    if (owner != null) {
      pets.setOwnerInfo(owner.copyWith(address: address.formatted));
    }

    if (!mounted) return;
    setState(() => _saving = false);
    context.backOr(AppRoutes.account);
  }

  void _clearError(String key) {
    if (_errors.containsKey(key)) setState(() => _errors.remove(key));
  }

  @override
  Widget build(BuildContext context) {
    final hasSaved = context.watch<AddressProvider>().hasAddress;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: hasSaved ? 'Delivery address' : 'Add address',
              onBack: () => context.backOr(AppRoutes.account),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
                children: [
                  _field(
                    key: 'name',
                    label: 'Full name',
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
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.borderSoft)),
              ),
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
              child: AppButton(
                label: _saving ? 'Saving…' : 'Save address',
                height: AppTheme.ctaHeightCompact,
                onPressed: _saving ? null : _save,
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
                  color: AppTheme.danger,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
