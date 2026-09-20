import 'package:flutter/material.dart';

import '../theme/brand_assets.dart';
import '../theme/brand_identity.dart';

/// Compact app-icon badge + MEDCAIN wordmark for home / auth headers.
///
/// Uses the black-field icon so the white/blue mark stays visible on light
/// paper — the transparent splash mark would wash out.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.markSize = 28,
    this.showTagline = false,
    this.alignment = MainAxisAlignment.start,
    this.compact = false,
  });

  final double markSize;
  final bool showTagline;
  final MainAxisAlignment alignment;

  /// Tighter letter spacing / smaller type for app bars.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      header: true,
      label: BrandIdentity.displayName,
      child: Column(
        crossAxisAlignment: alignment == MainAxisAlignment.center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: alignment,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(markSize * 0.22),
                child: Image.asset(
                  BrandAssets.appIcon,
                  width: markSize,
                  height: markSize,
                  filterQuality: FilterQuality.high,
                  semanticLabel: BrandIdentity.displayName,
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Text(
                BrandIdentity.displayName,
                style: (compact
                        ? textTheme.titleMedium
                        : textTheme.titleLarge)
                    ?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          if (showTagline) ...[
            const SizedBox(height: 4),
            Text(
              BrandIdentity.tagline,
              textAlign: alignment == MainAxisAlignment.center
                  ? TextAlign.center
                  : TextAlign.start,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.15,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
