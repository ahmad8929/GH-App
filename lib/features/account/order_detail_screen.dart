import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/common.dart';
import '../../state/providers.dart';
import 'orders_screen.dart';

final _orderDetailProvider = FutureProvider.autoDispose
    .family<Order, String>((ref, id) => ref.watch(ordersApiProvider).byId(id));

class OrderDetailScreen extends ConsumerWidget {
  final String id;

  const OrderDetailScreen({super.key, required this.id});

  Future<void> _cancelItem(
      BuildContext context, WidgetRef ref, OrderItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this item?'),
        content: Text(item.listingTitle ?? 'This item'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep it')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel item')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(ordersApiProvider).cancelItem(item.id);
      ref.invalidate(_orderDetailProvider(id));
      ref.invalidate(ordersProvider);
      if (context.mounted) showSuccess(context, 'Item cancelled');
    } catch (err) {
      if (context.mounted) showError(context, err);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(_orderDetailProvider(id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyState(
            emoji: '🔍', title: 'Order not found', body: err.toString()),
        data: (order) => ListView(
          padding: const EdgeInsets.all(AppTokens.s4),
          children: [
            Text(order.orderNumber, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppTokens.s1),
            Row(
              children: [
                Text('Placed ${formatDate(order.createdAt)}  ',
                    style: theme.textTheme.bodySmall),
                StatusPill(order.paymentStatus,
                    label: order.paymentStatus == 'unpaid'
                        ? 'Pay on delivery'
                        : order.paymentStatus),
              ],
            ),
            const SizedBox(height: AppTokens.s4),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.s3),
                child: Column(
                  children: [
                    ...order.items.map((item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: AppTokens.brSm,
                            child: SizedBox(
                              width: 48 * AppTokens.scale,
                              height: 48 * AppTokens.scale,
                              child: item.listingImage != null
                                  ? CachedNetworkImage(
                                      imageUrl: item.listingImage!,
                                      fit: BoxFit.cover)
                                  : Container(
                                      color: AppTokens.tint,
                                      alignment: Alignment.center,
                                      child: const Text('📦')),
                            ),
                          ),
                          title: Text(item.listingTitle ?? 'Item',
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusPill(item.status,
                                  label:
                                      orderItemStatusLabels[item.status]),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(inr(item.finalAmount)),
                              if (item.cancellable)
                                InkWell(
                                  onTap: () =>
                                      _cancelItem(context, ref, item),
                                  child: Text('Cancel',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                              color: AppTokens.danger)),
                                ),
                            ],
                          ),
                        )),
                    const Divider(),
                    _row('Subtotal', inr(order.subtotal)),
                    if ((double.tryParse(order.discountAmount) ?? 0) > 0)
                      _row('Discount', '−${inr(order.discountAmount)}'),
                    _row('Total', inr(order.finalAmount), bold: true),
                  ],
                ),
              ),
            ),
            if (order.deliveryAddress != null) ...[
              const SizedBox(height: AppTokens.s3),
              Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.local_shipping_outlined, color: AppTokens.primary),
                  title: const Text('Delivering to'),
                  subtitle: Text(
                    '${order.deliveryAddress!.name} · ${order.deliveryAddress!.phone}\n'
                    '${order.deliveryAddress!.line1}, ${order.deliveryAddress!.city} ${order.deliveryAddress!.pincode}'
                    '${order.deliveryNote != null ? '\nNote: ${order.deliveryNote}' : ''}',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.s1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
            Text(value,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                    color: bold ? AppTokens.primary : null)),
          ],
        ),
      );
}
