import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes.dart';
import '../../config/assets.dart';
import '../../config/theme.dart';
import '../../widgets/app_button.dart';
import 'widgets/auth_art_layout.dart';

/// Screen 08 — Verify code.
///
/// Six single-character boxes with a resend countdown. Focus advances as
/// digits are typed and steps back on delete.
class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({super.key});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  static const _length = 6;
  static const _resendSeconds = 42;

  final _controllers =
      List.generate(_length, (_) => TextEditingController());
  final _nodes = List.generate(_length, (_) => FocusNode());

  late int _remaining = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _remaining = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() => _remaining = 0);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();
  bool get _complete => _code.length == _length;

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < _length - 1) {
      _nodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  String get _countdown {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AuthArtLayout(
      gradient: const [
        Color(0xFFFFFFFF),
        Color(0xFFFBFAFD),
        Color(0xFFF2EFF8),
      ],
      title: 'Check your email',
      subtitle: Text.rich(
        TextSpan(
          text: 'We sent a 6-digit code to\n',
          children: [
            TextSpan(
              text: 'priya@email.com',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: AppTheme.bodyText,
      ),
      art: AppAssets.verifyCode,
      artWidth: 270,
      artLabel: 'Puppy waiting with a ball',
      onBack: () => context.pop(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _length; i++)
              Padding(
                padding: EdgeInsets.only(right: i == _length - 1 ? 0 : 10),
                child: _CodeBox(
                  controller: _controllers[i],
                  node: _nodes[i],
                  onChanged: (v) => _onChanged(i, v),
                  onBackspace: () {
                    if (_controllers[i].text.isEmpty && i > 0) {
                      _controllers[i - 1].clear();
                      _nodes[i - 1].requestFocus();
                      setState(() {});
                    }
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: Text.rich(
            TextSpan(
              text: "Didn't get it? ",
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: _remaining == 0 ? _startCountdown : null,
                    child: Text(
                      'Resend code',
                      style: AppTheme.font(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: _remaining == 0
                            ? AppTheme.action
                            : AppTheme.placeholder,
                      ),
                    ),
                  ),
                ),
                TextSpan(
                  text: _remaining == 0 ? '' : '  ·  $_countdown',
                  style: const TextStyle(color: AppTheme.muted),
                ),
              ],
            ),
            style: AppTheme.font(size: 13.5, color: AppTheme.body),
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Verify',
          onPressed:
              _complete ? () => context.push(AppRoutes.resetPassword) : null,
        ),
      ],
    );
  }
}

/// One 48×56 code cell. Filled cells take the action border and tinted fill.
class _CodeBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode node;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _CodeBox({
    required this.controller,
    required this.node,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  State<_CodeBox> createState() => _CodeBoxState();
}

class _CodeBoxState extends State<_CodeBox> {
  @override
  Widget build(BuildContext context) {
    final filled = widget.controller.text.isNotEmpty;

    return SizedBox(
      width: 48,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            widget.onBackspace();
          }
        },
        child: TextField(
          controller: widget.controller,
          focusNode: widget.node,
          onChanged: widget.onChanged,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          cursorColor: AppTheme.action,
          style: AppTheme.font(
            size: 22,
            weight: FontWeight.w800,
            color: AppTheme.ink,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: filled ? const Color(0xFFF1EFF8) : AppTheme.surface,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: filled ? AppTheme.action : AppTheme.border,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.action, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
