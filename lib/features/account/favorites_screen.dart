import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/listing_card.dart';
import '../../state/favorites_state.dart';
import '../../state/providers.dart';

final _favoritesListProvider =
    FutureProvider.autoDispose<List<Favorite>>((ref) async {
  // Re-fetch whenever the favorites set changes (toggles elsewhere).
  ref.watch(favoritesControllerProvider);
  final res = await ref.watch(favoritesApiProvider).list();
  return res.data.where((favorite) => favorite.listing != null).toList();
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(_favoritesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyState(
            emoji: '😵',
            title: "Couldn't load favorites",
            body: err.toString()),
        data: (items) => items.isEmpty
            ? EmptyState(
                emoji: '💙',
                title: 'No favorites yet',
                body: 'Tap the heart on any listing to keep it here.',
                ctaLabel: 'Browse the store',
                onCta: () => context.go('/shop'),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(AppTokens.s4),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisExtent: 250,
                  crossAxisSpacing: AppTokens.s3,
                  mainAxisSpacing: AppTokens.s3,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    ListingCard(listing: items[index].listing!),
              ),
      ),
    );
  }
}
