import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// Logo + title used on splash-adjacent auth screens.
class AuthHero extends StatelessWidget {
  const AuthHero({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      children: [
        Image.asset(
          'assets/branding/splash_logo.png',
          width: 96,
          height: 96,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => Icon(
            Icons.medical_services_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
      ],
    );
  }
}
