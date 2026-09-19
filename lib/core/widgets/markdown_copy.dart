import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders stored markdown (sample answers, explanations) using the
/// surrounding theme. Plain text still looks like a normal paragraph.
///
/// Selection/copy is off on purpose — DA, EX, tutor feedback, and review
/// answers are paid content. Links still open via [onTapLink].
///
/// Use this instead of [Text] inside a [ListView] — [MarkdownBody] does
/// not scroll on its own (`Markdown` would fight the parent scroll view).
class MarkdownCopy extends StatelessWidget {
  const MarkdownCopy({super.key, required this.data, this.style});

  final String data;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = style ?? theme.textTheme.bodyMedium;
    final sheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: base,
      strong: base?.copyWith(fontWeight: FontWeight.w700),
      em: base?.copyWith(fontStyle: FontStyle.italic),
      listBullet: base,
      blockquote: base?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      a: base?.copyWith(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
    );

    return MarkdownBody(
      data: data,
      selectable: false,
      styleSheet: sheet,
      onTapLink: (text, href, title) {
        if (href == null || href.isEmpty) return;
        final uri = Uri.tryParse(href);
        if (uri == null) return;
        launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    );
  }
}

/// Answer body with local font zoom (pinch with two fingers, or A− / A+).
///
/// Uses [MediaQuery] text scaling so markdown stays sharp (not a transform
/// zoom). One-finger scrolls still go to the parent [ListView]; only a
/// two-finger pinch changes the scale.
class ZoomableMarkdownCopy extends StatefulWidget {
  const ZoomableMarkdownCopy({super.key, required this.data});

  final String data;

  static const double minScale = 0.85;
  static const double maxScale = 2.0;
  static const double step = 0.15;

  @override
  State<ZoomableMarkdownCopy> createState() => _ZoomableMarkdownCopyState();
}

class _ZoomableMarkdownCopyState extends State<ZoomableMarkdownCopy> {
  double _scale = 1.0;
  // Captured at pinch start so each update is `start * gesture.scale`, not
  // compounded frame-by-frame (which would explode the font size).
  double _pinchStartScale = 1.0;

  void _setScale(double next) {
    final clamped = next.clamp(
      ZoomableMarkdownCopy.minScale,
      ZoomableMarkdownCopy.maxScale,
    );
    if (clamped == _scale) return;
    setState(() => _scale = clamped);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // scale(1) is the ambient factor (system accessibility text size).
    final ambient = media.textScaler.scale(1);
    final zoomed = media.copyWith(
      textScaler: TextScaler.linear(ambient * _scale),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Smaller text',
                onPressed: _scale <= ZoomableMarkdownCopy.minScale
                    ? null
                    : () => _setScale(_scale - ZoomableMarkdownCopy.step),
                icon: const Icon(Icons.text_decrease, size: 20),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Larger text',
                onPressed: _scale >= ZoomableMarkdownCopy.maxScale
                    ? null
                    : () => _setScale(_scale + ZoomableMarkdownCopy.step),
                icon: const Icon(Icons.text_increase, size: 20),
              ),
            ],
          ),
        ),
        // Two-finger pinch only — bail out on one pointer so the parent
        // ListView keeps vertical scroll.
        GestureDetector(
          onScaleStart: (_) {
            _pinchStartScale = _scale;
          },
          onScaleUpdate: (details) {
            if (details.pointerCount < 2) return;
            _setScale(_pinchStartScale * details.scale);
          },
          child: MediaQuery(
            data: zoomed,
            child: MarkdownCopy(data: widget.data),
          ),
        ),
      ],
    );
  }
}
