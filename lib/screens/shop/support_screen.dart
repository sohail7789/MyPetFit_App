import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

/// FAQ copy, verbatim from the design.
const _faqs = <({String question, String answer})>[
  (
    question: 'Where is my order?',
    answer: 'Open Track order from the order-placed screen or Orders in your '
        'account — the live timeline shows every step.',
  ),
  (
    question: 'Can I return a product?',
    answer: 'Unopened products within 7 days, full refund. Opened consumables '
        "(chews, supplements) can't be returned for safety reasons.",
  ),
  (
    question: 'How are these products chosen?',
    answer: "Each pick maps to a category in your pet's report card — the "
        'weakest categories drive the top recommendations.',
  ),
  (
    question: 'Is the fitness score a diagnosis?',
    answer: "No. It's a lifestyle-based wellness indicator. Always consult "
        'your vet for medical concerns.',
  ),
];

/// Screen 29b — Help & support.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    semanticLabel: 'Back',
                    onPressed: () => context.backOr(AppRoutes.shop),
                  ),
                  const SizedBox(width: 12),
                  Text('Help & support', style: context.t.h2),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                children: [
                  // A "Chat with us" card sat here, promising replies "in
                  // under 5 minutes, 9 am – 9 pm" behind a Chat button whose
                  // handler was empty. There is no live chat to route anyone
                  // to, and a staffed-hours promise is a specific commitment
                  // to a real person. Email — further down, and real — is
                  // what support actually is today.
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: SectionLabel('Common questions'),
                  ),
                  const SizedBox(height: 12),
                  for (final faq in _faqs) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            faq.question,
                            style: AppTheme.font(
                              size: 14,
                              weight: FontWeight.w800,
                              color: context.c.ink,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            faq.answer,
                            style: AppTheme.font(
                              size: 12.5,
                              color: context.c.bodyStrong,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  AppCard(
                    background: context.c.surfaceLow,
                    child: Text.rich(
                      TextSpan(
                        text: 'Email us anytime at ',
                        children: [
                          TextSpan(
                            text: 'care@mypetfit.app',
                            style: AppTheme.font(
                              size: 13,
                              weight: FontWeight.w700,
                              color: context.c.actionText,
                            ),
                          ),
                          const TextSpan(
                            text: ' — include your order number for faster '
                                'help.',
                          ),
                        ],
                      ),
                      style: AppTheme.font(
                        size: 13,
                        color: context.c.bodyStrong,
                        height: 1.6,
                      ),
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
