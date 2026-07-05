import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/common.dart';

/// Advertiser opt-in and paid ad plans are not on the backend yet —
/// this stays a friendly "coming soon" (contract-first, don't fake it).
class AdvertiseScreen extends StatelessWidget {
  const AdvertiseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Advertise with us')),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.s4),
        children: [
          Text('Reach thousands of school families 📣',
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppTokens.s2),
          Text(
            'Advertise your coaching classes, bookstore, or school services right where parents and students already shop — using your regular Gyan Hub account.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTokens.s4),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Where your ads appear',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppTokens.s2),
                  ...const [
                    '🏠  Home banner (top)',
                    '✨  Home spotlight (mid)',
                    '📋  Marketplace sidebar (web)',
                  ].map((line) => Padding(
                        padding: const EdgeInsets.only(bottom: AppTokens.s1),
                        child: Text(line),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s4),
          const ComingSoonCard(
            emoji: '🚀',
            title: 'Advertiser sign-up opens soon',
            body:
                'Opt-in, plans, and creative uploads are nearly ready. Watch this space!',
          ),
        ],
      ),
    );
  }
}
