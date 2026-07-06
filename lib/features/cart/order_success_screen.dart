import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/ad_banner.dart';
import '../../shared/widgets/common.dart';
import '../../state/providers.dart';

final _orderProvider = FutureProvider.family<Order, String>(
    (ref, id) => ref.watch(ordersApiProvider).byId(id));

class OrderSuccessScreen extends ConsumerWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(_orderProvider(orderId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Order placed')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyState(
            emoji: '🔍', title: "Couldn't load the order", body: err.toString()),
        data: (order) => ListView(
          padding: const EdgeInsets.all(AppTokens.s4),
          children: [
            const SizedBox(height: AppTokens.s4),
            const Center(child: Text('🎉', style: TextStyle(fontSize: 56))),
            const SizedBox(height: AppTokens.s3),
            Center(
              child:
                  Text('Order placed!', style: theme.textTheme.headlineMedium),
            ),
            const SizedBox(height: AppTokens.s1),
            Center(
              child: Text(
                '${order.orderNumber} · ${formatDate(order.createdAt)}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppTokens.s2),
            Center(
              child: StatusPill(order.paymentStatus,
                  label: order.paymentStatus == 'unpaid'
                      ? 'Pay on delivery'
                      : order.paymentStatus),
            ),
            const SizedBox(height: AppTokens.s5),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Items', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppTokens.s2),
                    ...order.items.map((item) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppTokens.s2),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(item.listingTitle ?? 'Item')),
                              StatusPill(item.status,
                                  label: orderItemStatusLabels[item.status]),
                              const SizedBox(width: AppTokens.s2),
                              Text(inr(item.finalAmount)),
                            ],
                          ),
                        )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: theme.textTheme.titleMedium),
                        Text(inr(order.finalAmount),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: AppTokens.primary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.s4),
            FilledButton(
              onPressed: () => context.push('/orders/${order.id}'),
              child: const Text('Track my order'),
            ),
            const SizedBox(height: AppTokens.s2),
            OutlinedButton(
              onPressed: () => context.go('/shop'),
              child: const Text('Keep shopping'),
            ),
            const SizedBox(height: AppTokens.s5),
            const AdBanner(placement: 'order_success'),
          ],
        ),
      ),
    );
  }
}
