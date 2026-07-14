import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/ad_banner.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/listing_image.dart';
import '../../shared/widgets/quantity_stepper.dart';
import '../../state/auth_state.dart';
import '../../state/cart_state.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponController = TextEditingController();
  bool _couponBusy = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final signedIn = ref.read(authControllerProvider).isSignedIn;
    if (!signedIn) {
      context.push('/login?next=/cart');
      return;
    }
    setState(() => _couponBusy = true);
    try {
      final result = await ref
          .read(cartControllerProvider.notifier)
          .applyCoupon(_couponController.text.trim());
      if (mounted) {
        showSuccess(context,
            'Coupon ${result.code} applied — you save ${inr(result.discountAmount)}!');
      }
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _couponBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    final signedIn =
        ref.watch(authControllerProvider.select((a) => a.isSignedIn));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (cart.lines.isNotEmpty)
            TextButton(
              onPressed: () =>
                  ref.read(cartControllerProvider.notifier).clear(),
              child: const Text('Clear'),
            ),
        ],
      ),
      body: cart.loading
          ? const Center(child: CircularProgressIndicator())
          : cart.lines.isEmpty
              ? EmptyState(
                  emoji: '🛒',
                  title: 'Your cart is empty',
                  body:
                      'Every item is one-of-a-kind — grab it before it\'s gone!',
                  ctaLabel: 'Start shopping',
                  onCta: () => context.go('/shop'),
                )
              : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                          AppTokens.s4, AppTokens.s3, AppTokens.s4, 0),
                      child: AdBanner(placement: 'cart'),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppTokens.s4),
                        itemCount: cart.lines.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppTokens.s3),
                        itemBuilder: (context, index) {
                          final line = cart.lines[index];
                          final listing = line.listing;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppTokens.s3),
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () =>
                                        context.push('/listing/${listing.id}'),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: AppTokens.brSm,
                                          child: SizedBox(
                                            width: 52 * AppTokens.scale,
                                            height: 52 * AppTokens.scale,
                                            child:
                                                ListingImage(listing: listing),
                                          ),
                                        ),
                                        const SizedBox(width: AppTokens.s3),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(listing.title,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme.titleSmall),
                                              Text(
                                                  listing.isBulk
                                                      ? '${inr(line.unitPrice)}/unit'
                                                      : conditionLabels[listing
                                                              .condition] ??
                                                          listing.condition,
                                                  style: theme
                                                      .textTheme.labelSmall
                                                      ?.copyWith(
                                                          color: AppTokens
                                                              .inkSoft)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: AppTokens.s2),
                                        Text(inr(line.lineTotal),
                                            style: theme.textTheme.titleSmall),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppTokens.s2),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (listing.isBulk)
                                        QuantityStepper(
                                          value: line.quantity,
                                          min: listing.moq,
                                          max: listing.stock,
                                          removableBelowMin: true,
                                          onChanged: (qty) => ref
                                              .read(cartControllerProvider
                                                  .notifier)
                                              .setQuantity(line, qty),
                                        )
                                      else
                                        const SizedBox.shrink(),
                                      InkWell(
                                        onTap: () => ref
                                            .read(
                                                cartControllerProvider.notifier)
                                            .remove(line),
                                        child: Text('Remove',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                    color: AppTokens.danger)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(AppTokens.s4),
                      decoration: BoxDecoration(
                        color: AppTokens.surface,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppTokens.radiusLg)),
                        boxShadow: AppTokens.softShadow,
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (cart.coupon == null)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _couponController,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      decoration: const InputDecoration(
                                          hintText: 'Coupon code'),
                                    ),
                                  ),
                                  const SizedBox(width: AppTokens.s2),
                                  OutlinedButton(
                                    onPressed:
                                        _couponBusy ? null : _applyCoupon,
                                    child:
                                        Text(_couponBusy ? '…' : 'Apply'),
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Coupon ${cart.coupon!.code} · −${inr(cart.coupon!.discountAmount)}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              color: AppTokens.success),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => ref
                                        .read(cartControllerProvider.notifier)
                                        .clearCoupon(),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            const SizedBox(height: AppTokens.s2),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    'Subtotal (${cart.count} item${cart.count == 1 ? '' : 's'})'),
                                Text(inr(cart.subtotal)),
                              ],
                            ),
                            if (cart.coupon != null) ...[
                              const SizedBox(height: AppTokens.s1),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Discount'),
                                  Text('−${inr(cart.coupon!.discountAmount)}'),
                                ],
                              ),
                            ],
                            const Divider(height: AppTokens.s4),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total',
                                    style: theme.textTheme.titleMedium),
                                Text(inr(cart.total),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                            color: AppTokens.primary)),
                              ],
                            ),
                            const SizedBox(height: AppTokens.s3),
                            FilledButton(
                              onPressed: () => signedIn
                                  ? context.push('/checkout')
                                  : context.push('/login?next=/checkout'),
                              child: Text(signedIn
                                  ? 'Checkout'
                                  : 'Log in to checkout'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
