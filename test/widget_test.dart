import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyan_hub/core/format.dart';
import 'package:gyan_hub/core/models/models.dart';
import 'package:gyan_hub/core/theme/app_theme.dart';
import 'package:gyan_hub/shared/widgets/common.dart';

void main() {
  group('formatting', () {
    test('inr formats rupees and treats zero/null as Free', () {
      expect(inr('650.00'), '₹650');
      expect(inr(0), 'Free');
      expect(inr(null), 'Free');
      expect(inr('not-a-number'), '—');
    });
  });

  group('models', () {
    test('Listing parses the backend shape (decimal strings, embeds)', () {
      final listing = Listing.fromJson({
        'id': 'abc-123',
        'title': 'NCERT Science Class 8',
        'price': '210.00',
        'originalPrice': '380.00',
        'condition': 'like_new',
        'listingType': 'sale',
        'status': 'approved',
        'images': ['https://example.com/a.jpg'],
        'isFeatured': true,
        'viewCount': 7,
        'category': {'id': 'c1', 'name': 'Old Books', 'slug': 'old-books'},
        'createdAt': '2026-07-01T20:53:11.316Z',
      });
      expect(listing.priceValue, 210.0);
      expect(listing.hasDiscount, isTrue);
      expect(listing.category?.slug, 'old-books');
      // Round-trips for the guest-cart snapshot.
      final copy = Listing.fromJson(listing.toJson());
      expect(copy.title, listing.title);
      expect(copy.images, listing.images);
    });

    test('Pagination parses and OrderItem knows cancellable states', () {
      final pagination = Pagination.fromJson({
        'total': 15,
        'page': 1,
        'limit': 12,
        'totalPages': 2,
        'hasNext': true,
        'hasPrev': false,
      });
      expect(pagination.hasNext, isTrue);

      final item = OrderItem.fromJson(
          {'id': 'i1', 'status': 'packed', 'finalAmount': '90.00'});
      expect(item.cancellable, isTrue);
      final delivered = OrderItem.fromJson(
          {'id': 'i2', 'status': 'delivered', 'finalAmount': '90.00'});
      expect(delivered.cancellable, isFalse);
    });
  });

  testWidgets('theme is light and EmptyState renders its CTA',
      (tester) async {
    var tapped = false;
    final theme = buildAppTheme();
    expect(theme.brightness, Brightness.light);

    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(
        body: EmptyState(
          title: 'Your cart is empty',
          body: 'Grab something great!',
          ctaLabel: 'Start shopping',
          onCta: () => tapped = true,
        ),
      ),
    ));

    expect(find.text('Your cart is empty'), findsOneWidget);
    await tester.tap(find.text('Start shopping'));
    expect(tapped, isTrue);
  });
}
