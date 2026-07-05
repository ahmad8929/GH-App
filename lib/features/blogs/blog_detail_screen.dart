import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/common.dart';
import '../../state/providers.dart';

final _postProvider = FutureProvider.family<BlogPost, String>(
    (ref, slug) => ref.watch(blogsApiProvider).bySlug(slug));

class BlogDetailScreen extends ConsumerWidget {
  final String slug;

  const BlogDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(_postProvider(slug));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Article')),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(
            emoji: '📰',
            title: "This article isn't ready yet",
            body: 'Head back to see what else is around.'),
        data: (post) => ListView(
          padding: const EdgeInsets.all(AppTokens.s4),
          children: [
            Text(post.title, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppTokens.s2),
            Text('${post.author} · ${formatDate(post.publishedAt)}',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: AppTokens.s3),
            if (post.cover != null)
              ClipRRect(
                borderRadius: AppTokens.brLg,
                child: CachedNetworkImage(
                    imageUrl: post.cover!, fit: BoxFit.cover),
              ),
            // Trusted first-party CMS content.
            Html(data: post.contentHtml),
            const SizedBox(height: AppTokens.s4),
          ],
        ),
      ),
    );
  }
}
