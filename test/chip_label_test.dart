import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyan_hub/core/theme/app_theme.dart';
import 'package:gyan_hub/core/theme/app_tokens.dart';

/// Guards the filter-sheet chips: selected labels must be white (on the ink
/// pill) and unselected labels must be ink (on the white pill) — never
/// invisible white-on-white.
Color _labelColor(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  return paragraph.text.style!.color!;
}

void main() {
  testWidgets('ChoiceChip labels stay readable in both states', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: Wrap(
          children: [
            ChoiceChip(
                label: const Text('Old Books'),
                selected: false,
                onSelected: (_) {}),
            ChoiceChip(
                label: const Text('Newest'),
                selected: true,
                onSelected: (_) {}),
          ],
        ),
      ),
    ));

    expect(_labelColor(tester, 'Old Books'), AppTokens.ink,
        reason: 'unselected chip must show ink text on its white pill');
    expect(_labelColor(tester, 'Newest'), Colors.white,
        reason: 'selected chip must show white text on its ink pill');
  });

  testWidgets('FilterChip labels stay readable in both states', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: Wrap(
          children: [
            FilterChip(
                label: const Text('Good'),
                selected: false,
                onSelected: (_) {}),
            FilterChip(
                label: const Text('Fair'),
                selected: true,
                onSelected: (_) {}),
          ],
        ),
      ),
    ));

    expect(_labelColor(tester, 'Good'), AppTokens.ink);
    expect(_labelColor(tester, 'Fair'), Colors.white);
  });
}
