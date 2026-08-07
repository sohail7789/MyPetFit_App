import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../models/milestone.dart';
import '../presentation/milestone_formatter.dart';

/// One health milestone, with the date it was first earned.
///
/// Presentation only. The words come from a [MilestoneFormatter] and the
/// grouping from the milestone itself; this decides only how they look.
class MilestoneCard extends StatelessWidget {
  final Milestone milestone;
  final MilestoneFormatter formatter;

  const MilestoneCard({
    super.key,
    required this.milestone,
    this.formatter = const DefaultMilestoneFormatter(),
  });

  @override
  Widget build(BuildContext context) {
    final title = formatter.title(milestone.kind);
    final description = formatter.description(milestone.kind);
    final earned = _earnedOn(milestone.earnedAt);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$title. $description. Reached $earned',
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 12, 14, 12),
        decoration: BoxDecoration(
          color: context.c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCardSmall),
          border: Border.all(color: context.c.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.c.tint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _glyph(milestone.group),
                size: 17,
                color: context.c.actionText,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.font(
                      size: 14,
                      weight: FontWeight.w800,
                      color: context.c.ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTheme.font(
                      size: 12.5,
                      color: context.c.body,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // When it was first reached. A milestone without a date is
                  // a badge; with one it is part of the record.
                  Text(
                    'Reached $earned',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.font(
                      size: 11.5,
                      weight: FontWeight.w700,
                      color: context.c.muted,
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

  IconData _glyph(MilestoneGroup group) => switch (group) {
        MilestoneGroup.consistency => Icons.event_repeat_rounded,
        MilestoneGroup.health => Icons.favorite_outline_rounded,
        MilestoneGroup.improvement => Icons.trending_up_rounded,
      };
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _earnedOn(DateTime when) {
  final d = when.toLocal();
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}
