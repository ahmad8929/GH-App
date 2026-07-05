import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Small shared building blocks used across screens.

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s2),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? body;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const EmptyState({
    super.key,
    this.emoji = '🎒',
    required this.title,
    this.body,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: AppTokens.s3),
            Text(title,
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            if (body != null) ...[
              const SizedBox(height: AppTokens.s2),
              Text(body!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
            ],
            if (ctaLabel != null) ...[
              const SizedBox(height: AppTokens.s4),
              FilledButton(onPressed: onCta, child: Text(ctaLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class ComingSoonCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;

  const ComingSoonCard({
    super.key,
    this.emoji = '🚀',
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s5),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: AppTokens.s3),
            Text(title,
                style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppTokens.s2),
            Text(body,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: AppTokens.s3),
            const AppPill(label: 'Coming soon', color: AppTokens.accent),
          ],
        ),
      ),
    );
  }
}

class AppPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;

  const AppPill({
    super.key,
    required this.label,
    this.color = AppTokens.tint,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s3, vertical: AppTokens.s1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor ?? AppTokens.primaryDark,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'approved':
    case 'delivered':
    case 'completed':
    case 'paid':
    case 'confirmed':
      return AppTokens.success;
    case 'pending':
    case 'packed':
    case 'assigned':
    case 'in_transit':
    case 'pickup_scheduled':
    case 'unpaid':
      return AppTokens.warning;
    case 'rejected':
    case 'cancelled':
    case 'returned':
      return AppTokens.danger;
    default:
      return AppTokens.lavender;
  }
}

class StatusPill extends StatelessWidget {
  final String status;
  final String? label;

  const StatusPill(this.status, {super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s3, vertical: AppTokens.s1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Text(
        label ?? status.replaceAll('_', ' '),
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

Future<void> showError(BuildContext context, Object error) async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error.toString()),
      backgroundColor: AppTokens.danger,
    ),
  );
}

void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: AppTokens.success),
  );
}
