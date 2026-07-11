import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';

const _books = 'assets/images/categories/books.jpg';
const _notebook = 'assets/images/categories/notebook.jpg';
const _stationery = 'assets/images/categories/stationery.jpg';
const _art = 'assets/images/categories/art.jpg';
const _atlas = 'assets/images/categories/atlas.jpg';
const _uniform = 'assets/images/categories/uniform.jpg';

/// Picks a bundled, category-appropriate image for a listing that has no
/// uploaded photo of its own. Keeps the shop looking real for demos until
/// every listing gets its own seeded image in the backend.
///
/// Specific item types (atlas, art kit, notebook, uniform, stationery) are
/// matched by keyword first; anything else falls back to its category, and
/// finally to a generic stack of books.
String listingPlaceholderAsset(Listing listing) {
  final haystack = [
    listing.title,
    listing.subject ?? '',
    listing.category?.name ?? '',
    listing.category?.slug ?? '',
  ].join(' ').toLowerCase();

  // Match on a leading word boundary so plurals/suffixes still hit
  // ("Colors", "Notebooks") without matching mid-word — e.g. "art" must not
  // match "Wren & Martin".
  bool has(List<String> keys) =>
      keys.any((k) => RegExp('\\b${RegExp.escape(k)}').hasMatch(haystack));

  if (has(['atlas', 'geography', 'map', 'globe'])) return _atlas;
  if (has(['art', 'paint', 'brush', 'colour', 'color', 'crayon'])) return _art;
  if (has(['notebook', 'diary', 'journal'])) return _notebook;
  if (has(['uniform', 'blazer', 'pinafore', 'tunic', 'shirt', 'skirt'])) {
    return _uniform;
  }
  if (has(['geometry', 'pencil', 'eraser', 'sharpener', 'compass', 'ruler',
      'stationery', 'stationary'])) {
    return _stationery;
  }

  final slug = (listing.category?.slug ?? '').toLowerCase();
  if (slug.contains('uniform')) return _uniform;
  if (slug.contains('notebook')) return _notebook;
  if (slug.contains('stationery')) return _stationery;

  // old-books, new-books, and anything uncategorised default to books.
  return _books;
}

/// Renders a listing's photo, falling back to a category-appropriate bundled
/// image when the listing has no uploaded photo (or the network image fails).
class ListingImage extends StatelessWidget {
  final Listing listing;
  final int index;
  final BoxFit fit;

  const ListingImage({
    super.key,
    required this.listing,
    this.index = 0,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final asset = listingPlaceholderAsset(listing);
    final fallback = Image.asset(asset, fit: fit);

    if (index < listing.images.length && listing.images[index].isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: listing.images[index],
        fit: fit,
        placeholder: (_, _) => Container(color: AppTokens.tint),
        errorWidget: (_, _, _) => fallback,
      );
    }
    return fallback;
  }
}
