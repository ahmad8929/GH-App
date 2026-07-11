/// End-to-end drive of the real app against the live backend
/// (http://10.0.2.2:5000/api on the Android emulator).
///
/// Run: flutter test integration_test -d emulator-5554
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyan_hub/main.dart' as app;
import 'package:gyan_hub/shared/widgets/listing_card.dart';
import 'package:integration_test/integration_test.dart';

const apiBase = 'http://10.0.2.2:5000/api';
final stamp = DateTime.now().millisecondsSinceEpoch;
final email = 'e2e.app.$stamp@gyanhub.dev';
final sacTitle = 'E2E App Test Book $stamp';

/// Poll-pump until [finder] matches (integration tests hit a real network,
/// so pumpAndSettle alone can hang on spinners).
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 25),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.tap(finder, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 400));
}

/// Seed a sacrificial approved listing via the admin API so checkout doesn't
/// consume the shared demo catalog.
Future<void> seedSacrificialListing() async {
  final client = HttpClient();
  Future<Map<String, dynamic>> call(String path,
      {String method = 'POST',
      Map<String, dynamic>? body,
      String? token}) async {
    final req = await client.openUrl(method, Uri.parse('$apiBase$path'));
    req.headers.contentType = ContentType.json;
    if (token != null) req.headers.set('Authorization', 'Bearer $token');
    if (body != null) req.write(jsonEncode(body));
    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    return jsonDecode(text) as Map<String, dynamic>;
  }

  final login = await call('/admin/auth/login', body: {
    'email': 'superadmin@gyanhub.com',
    'password': 'SuperAdmin@123',
  });
  final token = login['accessToken'] as String;
  await call('/admin/listings', token: token, body: {
    'title': sacTitle,
    'description': 'Temporary listing for the app e2e run.',
    'price': 120,
    'condition': 'good',
    'listingType': 'sale',
    'city': 'Testville',
  });
  client.close();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('golden path: register → buy → cancel → sell/donate → browse',
      (tester) async {
    await seedSacrificialListing();

    await app.main();
    await tester.pump(const Duration(seconds: 2));

    // ---- Home renders live data ----
    await waitFor(tester, find.text('Shop by category'));

    // ---- Register ----
    await tapAndSettle(tester, find.text('Account'));
    await waitFor(tester, find.text('Create an account'));
    await tapAndSettle(tester, find.text('Create an account'));
    await waitFor(tester, find.text('Join the club 🎉'));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name'), 'E2E App Tester');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), email);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password (min 8 characters)'),
        'Password123!');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'Password123!');
    await tapAndSettle(tester, find.text('Create account').last);
    // Home again, personalized + announcements strip (signed-in only).
    await waitFor(tester, find.textContaining('Hi, E2E'),
        timeout: const Duration(seconds: 30));

    // ---- Shop: search the sacrificial listing, open it ----
    await tapAndSettle(tester, find.text('Shop'));
    await waitFor(tester, find.byType(TextField).first);
    await tester.enterText(
        find.byType(TextField).first, 'E2E App Test Book $stamp');
    await waitFor(tester, find.textContaining('E2E App Test Book'),
        timeout: const Duration(seconds: 30));
    await tapAndSettle(
        tester, find.textContaining('E2E App Test Book').first);

    // ---- Detail: sold by Gyaan Hub, favorite toggle, add to cart ----
    await waitFor(tester, find.text('Sold by Gyaan Hub'));
    await tapAndSettle(tester, find.byIcon(Icons.favorite_border).first);
    await waitFor(tester, find.text('Saved to favorites'));
    await tapAndSettle(tester, find.text('Add to cart'));
    await waitFor(tester, find.text('Added to cart'));
    // Back to the shell.
    await tapAndSettle(tester, find.byType(BackButton).first);

    // ---- Cart: coupon + checkout ----
    await tapAndSettle(tester, find.text('Cart'));
    await waitFor(tester, find.textContaining('Subtotal'));
    await tester.enterText(
        find.widgetWithText(TextField, 'Coupon code'), 'WELCOME10');
    await tapAndSettle(tester, find.text('Apply'));
    await waitFor(tester, find.textContaining('Coupon WELCOME10'),
        timeout: const Duration(seconds: 30));
    await tapAndSettle(tester, find.text('Checkout'));

    await waitFor(tester, find.text('Delivery details'));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone'), '+911234567890');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Address (house, street, area)'),
        '12 Test Lane');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'City'), 'Testville');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Pincode'), '110001');
    final placeButton = find.textContaining('Place order');
    await tester.ensureVisible(placeButton);
    await tapAndSettle(tester, placeButton);

    // ---- Confirmation → order detail → cancel item ----
    await waitFor(tester, find.text('Order placed!'),
        timeout: const Duration(seconds: 40));
    await tapAndSettle(tester, find.text('Track my order'));
    await waitFor(tester, find.textContaining('Placed '));
    await tapAndSettle(tester, find.text('Cancel').first);
    await waitFor(tester, find.text('Cancel item')); // dialog
    await tapAndSettle(tester, find.text('Cancel item'));
    await waitFor(tester, find.text('Item cancelled'));
    await tapAndSettle(tester, find.byType(BackButton).first);

    // ---- Sell/Donate: submit one of each ----
    await tapAndSettle(tester, find.text('Sell/Donate'));
    await waitFor(tester, find.text('Submit an item'));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Item title'),
        'E2E Sell $stamp');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'How much would you like? (₹)'),
        '150');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Contact phone'), '+911234567890');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Pickup address'), '12 Test Lane');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'City'), 'Testville');
    final submitSell = find.text('Submit for pickup & payout');
    await tester.ensureVisible(submitSell);
    await tapAndSettle(tester, submitSell);
    // Lands on "My submissions" with the new request.
    await waitFor(tester, find.textContaining('E2E Sell $stamp'),
        timeout: const Duration(seconds: 40));

    // Donate flow.
    await tapAndSettle(tester, find.text('Submit an item'));
    await tapAndSettle(tester, find.text('Donate'));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Item title'),
        'E2E Donate $stamp');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Contact phone'), '+911234567890');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Pickup address'), '12 Test Lane');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'City'), 'Testville');
    final donateButton = find.text('Donate this item');
    await tester.ensureVisible(donateButton);
    await tapAndSettle(tester, donateButton);
    await waitFor(tester, find.textContaining('E2E Donate $stamp'),
        timeout: const Duration(seconds: 40));

    // ---- Notebook builder: live price + gated CTA ----
    await tapAndSettle(tester, find.text('Home'));
    await waitFor(tester, find.text('Custom Notebook'));
    await tapAndSettle(tester, find.text('Custom Notebook'));
    await waitFor(tester, find.text('Your notebook'));
    expect(find.text('Add to cart — coming soon'), findsOneWidget);
    await tapAndSettle(tester, find.byType(BackButton).first);

    // ---- Blog teaser → article ----
    await waitFor(tester, find.text('From the blog'));
    await tapAndSettle(
        tester, find.textContaining('Parity Pass').first);
    await waitFor(tester, find.byType(BackButton).first);
    await tapAndSettle(tester, find.byType(BackButton).first);

    // ---- Notification center loads ----
    await tapAndSettle(tester, find.byIcon(Icons.notifications_outlined));
    await waitFor(tester, find.text('Notifications'));
    // Either items or the friendly empty state — never a crash.
    await waitFor(tester, find.byType(Scaffold));
  });
}
