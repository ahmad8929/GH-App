import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/ad_banner.dart';
import '../../shared/widgets/common.dart';
import '../../state/auth_state.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    if (auth.status == AuthStatus.restoring) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (!auth.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: EmptyState(
          emoji: '🎒',
          title: 'Join the Gyaan Hub club',
          body:
              'One account for shopping, orders, favorites, selling back, and donating.',
          ctaLabel: 'Login',
          onCta: () => context.push('/login'),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s4),
            child: OutlinedButton(
              onPressed: () => context.push('/register'),
              child: const Text('Create an account'),
            ),
          ),
        ),
      );
    }

    final user = auth.user!;
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.s4),
        children: [
          Card(
            child: ListTile(
              onTap: () => context.push('/profile-edit'),
              leading: CircleAvatar(
                radius: 26 * AppTokens.scale,
                backgroundColor: AppTokens.primary,
                foregroundImage: user.avatar != null
                    ? CachedNetworkImageProvider(user.avatar!)
                    : null,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'G',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text('Hi, ${user.name.split(' ').first}! 👋',
                  style: theme.textTheme.titleMedium),
              subtitle: Text('${user.email} · ${user.userType}'),
              trailing: const Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: AppTokens.s3),
          const AdBanner(placement: 'account'),
          const SizedBox(height: AppTokens.s2),
          ...[
            (Icons.receipt_long_outlined, 'My orders', '/orders'),
            (Icons.volunteer_activism_outlined, 'My submissions', '/sell'),
            (Icons.favorite_outline, 'Favorites', '/favorites'),
            (Icons.notifications_outlined, 'Notifications', '/notifications'),
            (Icons.campaign_outlined, 'Advertise with us', '/advertise'),
            (Icons.palette_outlined, 'Theme', '/theme'),
          ].map((entry) => Card(
                margin: const EdgeInsets.only(bottom: AppTokens.s2),
                child: ListTile(
                  leading: Icon(entry.$1, color: AppTokens.primary),
                  title: Text(entry.$2),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => entry.$3 == '/sell'
                      ? context.go(entry.$3)
                      : context.push(entry.$3),
                ),
              )),
          const SizedBox(height: AppTokens.s4),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                showSuccess(context, 'Logged out. See you soon!');
              }
            },
            icon: const Icon(Icons.logout, color: AppTokens.danger),
            label: const Text('Log out',
                style: TextStyle(color: AppTokens.danger)),
          ),
        ],
      ),
    );
  }
}
