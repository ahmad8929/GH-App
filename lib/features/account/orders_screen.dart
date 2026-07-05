import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/common.dart';
import '../../state/providers.dart';

final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final res = await ref.watch(ordersApiProvider).mine();
  return res.data;
});

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyState(
            emoji: '😵', title: "Couldn't load orders", body: err.toString()),
        data: (items) => items.isEmpty
            ? EmptyState(
                emoji: '📦',
                title: 'No orders yet',
                body: 'When you buy something, it shows up here.',
                ctaLabel: 'Start shopping',
                onCta: () => context.go('/shop'),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(ordersProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppTokens.s4),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppTokens.s3),
                  itemBuilder: (context, index) {
                    final order = items[index];
                    return Card(
                      child: ListTile(
                        onTap: () => context.push('/orders/${order.id}'),
                        title: Text(order.orderNumber,
                            style: Theme.of(context).textTheme.titleSmall),
                        subtitle: Text(
                          '${formatDate(order.createdAt)} · ${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(inr(order.finalAmount),
                                style:
                                    Theme.of(context).textTheme.titleSmall),
                            StatusPill(order.paymentStatus,
                                label: order.paymentStatus == 'unpaid'
                                    ? 'Pay on delivery'
                                    : order.paymentStatus),
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
