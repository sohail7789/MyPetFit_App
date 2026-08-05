import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../widgets/paw_mark.dart';

/// Scaffolding placeholder for screens not yet rebuilt.
///
/// Every route starts here and is replaced phase by phase, so the skeleton
/// is navigable from the first build and it stays obvious what is outstanding.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final String? detail;

  const ComingSoonScreen({super.key, required this.title, this.detail});

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();

    return Scaffold(
      backgroundColor: context.c.surface,
      body: Stack(
        children: [
          PawWatermark(
            top: 90,
            left: -14,
            size: 86,
            color: context.c.actionText,
            opacity: 0.07,
            rotationDegrees: -18,
          ),
          PawWatermark(
            top: 170,
            right: 10,
            size: 54,
            color: context.c.startLight,
            opacity: 0.08,
            rotationDegrees: 14,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (canPop)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          color: context.c.ink,
                          iconSize: 20,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Center(
                    child: PawMark(
                      size: 64,
                      color: context.c.actionText,
                      opacity: 0.18,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: context.t.h2,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    detail ?? 'Not rebuilt yet.',
                    textAlign: TextAlign.center,
                    style: context.t.bodyText,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
