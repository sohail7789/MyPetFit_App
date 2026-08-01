import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'design_image.dart';

/// A looping, muted background clip from the design, with a still fallback.
///
/// Apple platforms have no WebM decoder, so [appleSource] (an HEVC-with-alpha
/// `.mov` or an H.264 `.mp4`) is used there when supplied. If no source plays —
/// missing file, unsupported codec, decode error — the [poster] still is shown
/// instead, which is also what the design specifies as the video's poster.
class DesignVideo extends StatefulWidget {
  /// WebM source, used on Android and web.
  final String source;

  /// Apple-compatible source. Without it, iOS and macOS show [poster].
  final String? appleSource;

  final String poster;
  final double width;
  final String? semanticLabel;

  const DesignVideo({
    super.key,
    required this.source,
    this.appleSource,
    required this.poster,
    required this.width,
    this.semanticLabel,
  });

  @override
  State<DesignVideo> createState() => _DesignVideoState();
}

class _DesignVideoState extends State<DesignVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;

  /// Null when this platform has nothing it can decode.
  String? get _playableSource {
    if (kIsWeb) return widget.source;
    if (Platform.isIOS || Platform.isMacOS) return widget.appleSource;
    return widget.source;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final source = _playableSource;
    if (source == null) {
      setState(() => _failed = true);
      return;
    }

    final controller = VideoPlayerController.asset(source);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      // Missing asset or codec the platform can't handle — fall back.
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = !_failed && controller != null && controller.value.isInitialized;

    if (!ready) {
      return DesignImage(
        widget.poster,
        width: widget.width,
        shadow: true,
        semanticLabel: widget.semanticLabel,
      );
    }

    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: SizedBox(
        width: widget.width,
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
