import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/pet_info.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_info_provider.dart';
import '../../widgets/floating_paws_background.dart';

/// Step 1: Owner (parent) profile screen.
class OwnerInfoScreen extends StatefulWidget {
  const OwnerInfoScreen({super.key});

  @override
  State<OwnerInfoScreen> createState() => _OwnerInfoScreenState();
}

class _OwnerInfoScreenState extends State<OwnerInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final owner = context.read<PetInfoProvider>().ownerInfo;
    if (owner != null) {
      _nameCtrl.text = owner.name;
      _contactCtrl.text = owner.contactNumber;
      _emailCtrl.text = owner.email;
      _addressCtrl.text = owner.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;
    context.read<PetInfoProvider>().setOwnerInfo(OwnerInfo(
      name: _nameCtrl.text.trim(),
      contactNumber: _contactCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
    ));
    context.push(AppRoutes.petInfo); // → pet detail screen
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Owner Profile')),
      body: FloatingPawsBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
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
                          color: AppTheme.tint(isDark, AppTheme.accentBlue,
                              AppTheme.lightAzure),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: AppTheme.interactive(isDark),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Parent profile',
                                style: theme.textTheme.headlineSmall),
                            const SizedBox(height: 2),
                            Text('Your details as the pet owner',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.section),

                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _contactCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Contact is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    // Shares the app-wide validator instead of a local
                    // `contains('@')` check, which accepted "@" as valid.
                    validator: AuthValidators.email,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Address (optional)',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  ElevatedButton(
                    onPressed: _onNext,
                    child: const Text('Next — Add Your Pet'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
