import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/common.dart';
import '../../state/providers.dart';

final _blogsProvider = FutureProvider<List<BlogPost>>((ref) async {
  final res = await ref.watch(blogsApiProvider).list();
  return res.data;
});

class BlogsScreen extends ConsumerWidget {
  const BlogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogs = ref.watch(_blogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blog')),
      body: blogs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(
            emoji: '📰',
            title: 'Our blog is warming up',
            body: 'Fresh articles are on the way — check back soon!'),
        data: (posts) => posts.isEmpty
            ? const EmptyState(
                emoji: '📰',
                title: 'Our blog is warming up',
                body: 'Fresh articles are on the way — check back soon!')
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(_blogsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppTokens.s4),
                  itemCount: posts.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppTokens.s3),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.push('/blogs/${post.slug}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (post.cover != null)
                              AspectRatio(
                                aspectRatio: 21 / 9,
                                child: CachedNetworkImage(
                                    imageUrl: post.cover!, fit: BoxFit.cover),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(AppTokens.s4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${post.author} · ${formatDate(post.publishedAt)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall,
                                  ),
                                  const SizedBox(height: AppTokens.s1),
                                  Text(post.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: AppTokens.s1),
                                  Text(
                                    post.excerpt,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
