import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders stored markdown (sample answers, explanations) using the
/// surrounding theme. Plain text still looks like a normal paragraph.
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
      selectable: true,
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
