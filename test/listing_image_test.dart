import 'package:flutter_test/flutter_test.dart';
import 'package:gyan_hub/core/models/models.dart';
import 'package:gyan_hub/shared/widgets/listing_image.dart';

Listing _listing(String title, {String? categoryName, String? slug}) => Listing(
      id: 't',
      title: title,
      condition: 'good',
      listingType: 'sale',
      status: 'approved',
      images: const [],
      isFeatured: false,
      viewCount: 0,
      category: categoryName == null
          ? null
          : CategoryRef(id: 'c', name: categoryName, slug: slug),
    );

void main() {
  group('listingPlaceholderAsset maps real seeded listings', () {
    final cases = <String, String>{
      // Books (the NCERT Class 8 example from the request) -> book image.
      'NCERT Science Class 8': 'books.jpg',
      'NCERT Mathematics Class 9': 'books.jpg',
      'RD Sharma Class 10 (2025 ed.)': 'books.jpg',
      'Wren & Martin English Grammar': 'books.jpg',
      // Geography -> globe/atlas.
      'Oxford School Atlas — New': 'atlas.jpg',
      // Uniforms.
      'St. Xavier\'s Blazer (L)': 'uniform.jpg',
      'School Pinafore Set (Age 8-9)': 'uniform.jpg',
      'DPS Summer Uniform Set (M)': 'uniform.jpg',
      // Notebooks.
      'Spiral Doodle Notebook A5': 'notebook.jpg',
      'Classmate Notebooks (Pack of 6)': 'notebook.jpg',
      // Stationery / geometry.
      'Geometry Box — Camlin': 'stationery.jpg',
      'Staff-curated Geometry Set': 'stationery.jpg',
      // Art.
      'Art Kit: Colors + Brushes': 'art.jpg',
    };

    cases.forEach((title, expectedFile) {
      test('"$title" -> $expectedFile', () {
        expect(listingPlaceholderAsset(_listing(title)), endsWith(expectedFile));
      });
    });

    test('falls back to books by category when title is generic', () {
      final l = _listing('Set of assorted items',
          categoryName: 'Old Books', slug: 'old-books');
      expect(listingPlaceholderAsset(l), endsWith('books.jpg'));
    });
  });
}
