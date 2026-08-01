import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/assets.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/design_image.dart';
import 'order_reference.dart';

enum _StepState { done, active, todo }

/// Screen 29 — Order tracking.
class OrderTrackingScreen extends StatelessWidget {
  final OrderReference? order;

  const OrderTrackingScreen({super.key, this.order});

  @override
  Widget build(BuildContext context) {
    final reference = order ?? OrderReference.create(itemCount: 0);

    final steps = <({String label, String time, _StepState state})>[
      (
        label: 'Order placed',
        time: reference.placedAtLabel,
        state: _StepState.done,
      ),
      (
        label: 'Packed at MyPetFit hub',
        time: 'Awaiting dispatch',
        state: _StepState.active,
      ),
      (label: 'Out for delivery', time: 'Not yet', state: _StepState.todo),
      (
        label: 'Delivered',
        time: 'Expected ${reference.arrivalLabel}',
        state: _StepState.todo,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.surface,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order ${reference.id}', style: AppTheme.h3),
                        const SizedBox(height: 2),
                        Text(
                          reference.summaryLabel,
                          style: AppTheme.font(
                            size: 12.5,
                            color: AppTheme.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 20),
                children: [
                  AppCard(
                    background: AppTheme.tintPanel,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const DesignImage(
                          AppAssets.orderTracking,
                          width: 74,
                          shadow: true,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Packed and on its way',
                                style: AppTheme.cardTitle,
                              ),
                              const SizedBox(height: 3),
                              Text.rich(
                                TextSpan(
                                  text: 'Arriving ',
                                  children: [
                                    TextSpan(
                                      text: reference.arrivalLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.ink,
                                      ),
                                    ),
                                  ],
                                ),
                                style: AppTheme.font(
                                  size: 13,
                                  color: AppTheme.body,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  for (var i = 0; i < steps.length; i++)
                    _TimelineRow(
                      label: steps[i].label,
                      time: steps[i].time,
                      state: steps[i].state,
                      isLast: i == steps.length - 1,
                    ),
                  AppCard(
                    child: Row(
                      children: [
                        const DesignImage(
                          AppAssets.emoQuestion,
                          width: 38,
                          height: 38,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Problem with this order?',
                                style: AppTheme.font(
                                  size: 13,
                                  color: AppTheme.bodyStrong,
                                  height: 1.45,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push(AppRoutes.support),
                                child: Text(
                                  'Chat with support',
                                  style: AppTheme.font(
                                    size: 13,
                                    weight: FontWeight.w700,
                                    color: AppTheme.action,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

class _TimelineRow extends StatelessWidget {
  final String label;
  final String time;
  final _StepState state;
  final bool isLast;

  const _TimelineRow({
    required this.label,
    required this.time,
    required this.state,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final done = state == _StepState.done;
    final active = state == _StepState.active;

    final dotColor = done
        ? AppTheme.success
        : active
            ? AppTheme.action
            : AppTheme.surface;
    final dotBorder = done
        ? AppTheme.success
        : active
            ? AppTheme.action
            : AppTheme.dotInactive;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: dotBorder, width: 2),
                ),
                alignment: Alignment.center,
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Colors.white,
                      )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.5,
                    constraints: const BoxConstraints(minHeight: 34),
                    color: done ? AppTheme.success : AppTheme.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTheme.font(
                      size: 14.5,
                      weight: FontWeight.w800,
                      color: state == _StepState.todo
                          ? AppTheme.muted
                          : AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: AppTheme.font(size: 12.5, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
