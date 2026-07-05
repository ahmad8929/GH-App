import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/common.dart';
import '../../state/providers.dart';

final _notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final res = await ref.watch(notificationsApiProvider).list();
  return res.data;
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(_notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyState(
            emoji: '😵',
            title: "Couldn't load notifications",
            body: err.toString()),
        data: (items) => items.isEmpty
            ? const EmptyState(
                emoji: '🔔',
                title: 'All caught up!',
                body: 'Order updates and news will appear here.')
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(_notificationsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppTokens.s4),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppTokens.s2),
                  itemBuilder: (context, index) {
                    final notification = items[index];
                    final unread =
                        !notification.isRead && !notification.isBroadcast;
                    return Card(
                      color: unread
                          ? AppTokens.tint.withValues(alpha: 0.55)
                          : null,
                      child: ListTile(
                        leading: Text(
                          switch (notification.type) {
                            'order_update' => '📦',
                            'promotion' => '🎁',
                            'listing_approved' => '✅',
                            'listing_rejected' => '❌',
                            'announcement' => '📣',
                            _ => '🔔',
                          },
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(notification.title,
                            style: Theme.of(context).textTheme.titleSmall),
                        subtitle: Text(
                          '${notification.body}\n${formatDate(notification.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        isThreeLine: true,
                        trailing: unread
                            ? const Icon(Icons.circle,
                                size: 10, color: AppTokens.primary)
                            : null,
                        onTap: unread
                            ? () async {
                                try {
                                  await ref
                                      .read(notificationsApiProvider)
                                      .markRead(notification.id);
                                  ref.invalidate(_notificationsProvider);
                                } catch (_) {
                                  // broadcast rows can't be marked read
                                }
                              }
                            : null,
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
