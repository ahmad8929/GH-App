import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../state/providers.dart';

/// Full list of shop categories, reached from the home page's "View All".
/// Picking one hands off to the Shop tab pre-filtered to that category, so the
/// catalog itself still lives in a single place.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Shop by category')),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.s4),
        children: [
          Text(
            'Browse the whole store',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppTokens.s1),
          Text(
            'Pick a category to see everything in it.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppTokens.inkSoft),
          ),
          const SizedBox(height: AppTokens.s4),
          ...shopCategories.map((category) => Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.s3),
                child: _CategoryCard(category: category),
              )),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ShopCategory category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppTokens.gradientFor(category.slug),
          borderRadius: AppTokens.brLg,
          boxShadow: AppTokens.softShadow,
        ),
        child: InkWell(
          borderRadius: AppTokens.brLg,
          onTap: () {
            if (category.slug == 'custom-notebooks') {
              context.push('/notebook');
            } else {
              context.go('/shop?cat=${category.slug}');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s4),
            child: Row(
              children: [
                Container(
                  width: 56 * AppTokens.scale,
                  height: 56 * AppTokens.scale,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: AppTokens.brMd,
                  ),
                  child: Text(category.emoji,
                      style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: AppTokens.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (category.blurb.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.s1),
                        Text(
                          category.blurb,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.s2),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
