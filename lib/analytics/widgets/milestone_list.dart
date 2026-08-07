import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../models/milestone.dart';
import '../presentation/milestone_formatter.dart';
import 'milestone_card.dart';

/// The health milestones a pet's record has reached.
///
/// **Earned only.** No locked row, no greyed-out badges waiting to be
/// collected: this is a health record, and a grid of things a pet has not
/// achieved turns it into a progress bar. Ordering is chronological, so the
/// list reads as a history rather than a scoreboard.
///
/// Provider-free, with an injectable formatter.
class MilestoneList extends StatelessWidget {
  final List<Milestone> milestones;
  final MilestoneFormatter formatter;

  final String title;
  final String subtitle;

  const MilestoneList({
    super.key,
    required this.milestones,
    this.formatter = const DefaultMilestoneFormatter(),
    this.title = 'Health milestones',
    this.subtitle = 'Moments worth remembering, in the order they happened.',
  });

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          container: true,
          excludeSemantics: true,
          label: '$title. $subtitle',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.font(
                  size: 16,
                  weight: FontWeight.w800,
                  color: context.c.ink,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTheme.font(
                  size: 12.5,
                  color: context.c.muted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < milestones.length; i++)
          Padding(
            padding:
                EdgeInsets.only(bottom: i == milestones.length - 1 ? 0 : 10),
            child: MilestoneCard(
              milestone: milestones[i],
              formatter: formatter,
            ),
          ),
      ],
    );
  }
}
