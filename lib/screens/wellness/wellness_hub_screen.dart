import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/blob_background.dart';
import '../../widgets/wellness_card.dart';

class WellnessHubScreen extends StatelessWidget {
  const WellnessHubScreen({super.key});

  static const _items = <_WellnessItem>[
    _WellnessItem(
      icon: Icons.medication_rounded,
      title: 'Supplements',
      subtitle: 'Daily vitamins & support',
      accent: AppTheme.primary,
      pastel: AppTheme.lightAzure,
    ),
    _WellnessItem(
      icon: Icons.monitor_heart_rounded,
      title: 'Symptoms log',
      subtitle: 'Track changes over time',
      accent: AppTheme.secondary,
      pastel: AppTheme.softPeach,
    ),
    _WellnessItem(
      icon: Icons.medical_services_rounded,
      title: 'Medications',
      subtitle: 'Manage prescriptions',
      accent: AppTheme.accentBlue,
      pastel: AppTheme.lightAzure,
    ),
    _WellnessItem(
      icon: Icons.local_hospital_rounded,
      title: 'Vet visits',
      subtitle: 'Schedule & history',
      accent: AppTheme.neutralDark,
      pastel: AppTheme.softLavender,
    ),
    _WellnessItem(
      icon: Icons.vaccines_rounded,
      title: 'Vaccinations',
      subtitle: 'Stay on schedule',
      accent: AppTheme.primary,
      pastel: AppTheme.softPeach,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Wellness')),
      body: BlobBackground(
        variant: BlobVariant.bottomLeft,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              AppTheme.darkBlueSurface,
                              const Color(0xFF232A44),
                            ]
                          : [AppTheme.lightAzure, AppTheme.lightGreen],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppTheme.hairline(isDark),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          // A solid white disc glared against the dark
                          // gradient; use the page background instead.
                          color: isDark
                              ? AppTheme.darkBlueBg
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.spa_rounded,
                          color: isDark
                              ? AppTheme.accentPink
                              : AppTheme.secondary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live well. Stay healthy.',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppTheme.heading(isDark),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Manage prescriptions and keep tabs on symptoms — all in one place.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.mutedText(isDark),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.section),
                Text(
                  'Manage your pet\'s wellness',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'These tools are on the way',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisExtent: 140,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  children: [
                    for (final item in _items)
                      WellnessCard(
                        icon: item.icon,
                        title: item.title,
                        subtitle: item.subtitle,
                        accent: item.accent,
                        pastel: item.pastel,
                        // Every tile here is unbuilt. Labelling them sets
                        // the expectation instead of dead-ending the tap.
                        badge: 'Soon',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('${item.title} is coming soon'),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WellnessItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color pastel;

  const _WellnessItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.pastel,
  });
}
