import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/locale_provider.dart';

/// Opens the language sheet. Shared by the sign-in chip and the account
/// setting so the two can never disagree about what is selected.
Future<void> showLanguagePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const LanguageSheet(),
  );
}

class LanguageSheet extends StatelessWidget {
  const LanguageSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: context.c.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: context.c.dotInactive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Language', style: context.t.h3),
            const SizedBox(height: 6),
            Text(
              'Choose how MyPetFit talks to you.',
              style: AppTheme.font(size: 13.5, color: context.c.body),
            ),
            const SizedBox(height: 16),
            for (final language in LocaleProvider.supported) ...[
              LanguageRow(
                language: language,
                selected: locale.code == language.code,
                onTap: language.available
                    ? () {
                        context.read<LocaleProvider>().select(language.code);
                        Navigator.of(context).pop();
                      }
                    : null,
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 4),
            Text(
              'Hindi and Marathi are being translated — including all 45 '
              'assessment questions — and will switch on here once ready.',
              style: AppTheme.font(
                size: 12.5,
                color: context.c.muted,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One selectable row. A null [onTap] renders the "coming soon" state.
class LanguageRow extends StatelessWidget {
  final AppLanguage language;
  final bool selected;
  final VoidCallback? onTap;

  const LanguageRow({
    super.key,
    required this.language,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Semantics(
      button: enabled,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Container(
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? context.c.tintPanel : context.c.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusCardSmall),
              border: Border.all(
                color: selected ? context.c.actionText : context.c.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.c.tint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    language.glyph,
                    style: AppTheme.font(
                      size: 14,
                      weight: FontWeight.w800,
                      color: context.c.actionText,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        language.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.font(
                          size: 15,
                          weight: FontWeight.w700,
                          color: context.c.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        enabled ? language.native : 'Coming soon',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.font(
                          size: 12.5,
                          color: context.c.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 22,
                    color: context.c.actionText,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
