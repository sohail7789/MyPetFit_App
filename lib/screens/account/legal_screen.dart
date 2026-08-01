import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../data/legal_content.dart';
import '../../widgets/settings_tile.dart';

/// Screens 34 and 35 — Terms of Service and Privacy Policy.
class LegalScreen extends StatelessWidget {
  final String title;
  final List<LegalClause> clauses;

  const LegalScreen({
    super.key,
    required this.title,
    required this.clauses,
  });

  const LegalScreen.terms({super.key})
      : title = 'Terms of Service',
        clauses = termsOfService;

  const LegalScreen.privacy({super.key})
      : title = 'Privacy Policy',
        clauses = privacyPolicy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(title: title, onBack: () => context.backOr(AppRoutes.account)),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
                itemCount: clauses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 18),
                itemBuilder: (context, i) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clauses[i].heading,
                      style: AppTheme.font(
                        size: 14.5,
                        weight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      clauses[i].body,
                      style: AppTheme.font(
                        size: 13,
                        color: AppTheme.bodyStrong,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
