import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/models/models.dart';
import '../../core/payment.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/common.dart';
import '../../state/auth_state.dart';
import '../../state/cart_state.dart';
import '../../state/providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  final _note = TextEditingController();
  String _method = 'cod';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.text = ref.read(authControllerProvider).user?.name ?? '';
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _line1, _city, _pincode, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final provider =
          paymentProviders.firstWhere((p) => p.id == _method && p.enabled);
      final coupon = ref.read(cartControllerProvider).coupon;
      final order = await ref.read(ordersApiProvider).checkout(
            couponCode: coupon?.code,
            deliveryAddress: DeliveryAddress(
              name: _name.text.trim(),
              phone: _phone.text.trim(),
              line1: _line1.text.trim(),
              city: _city.text.trim(),
              pincode: _pincode.text.trim(),
            ),
            deliveryNote: _note.text.trim(),
            paymentMethod: provider.id,
          );
      // Payment stub — order stays `unpaid`; a real gateway slots in via
      // the PaymentProvider interface without touching this flow.
      await provider.pay(order);
      await ref.read(cartControllerProvider.notifier).reload();
      if (!mounted) return;
      context.pushReplacement('/order-success/${order.id}');
    } catch (err) {
      setState(() => _error = err.toString());
      await ref.read(cartControllerProvider.notifier).reload();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    final theme = Theme.of(context);

    if (!cart.loading && cart.lines.isEmpty && !_busy) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: EmptyState(
          emoji: '🛒',
          title: 'Nothing to check out',
          ctaLabel: 'Browse the store',
          onCta: () => context.go('/shop'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s4),
          children: [
            Text('Delivery details', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppTokens.s3),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTokens.s3),
                decoration: BoxDecoration(
                  color: AppTokens.danger.withValues(alpha: 0.1),
                  borderRadius: AppTokens.brSm,
                ),
                child:
                    Text(_error!, style: TextStyle(color: AppTokens.danger)),
              ),
              const SizedBox(height: AppTokens.s3),
            ],
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppTokens.s3),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: (v) =>
                  (v == null || v.trim().length < 8) ? 'Enter a phone' : null,
            ),
            const SizedBox(height: AppTokens.s3),
            TextFormField(
              controller: _line1,
              decoration: const InputDecoration(
                  labelText: 'Address (house, street, area)'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppTokens.s3),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _city,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: AppTokens.s3),
                Expanded(
                  child: TextFormField(
                    controller: _pincode,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Pincode'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s3),
            TextFormField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Delivery note (optional)',
                  hintText: 'Landmark, preferred time…'),
            ),
            const SizedBox(height: AppTokens.s4),
            Text('Payment', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppTokens.s2),
            RadioGroup<String>(
              groupValue: _method,
              onChanged: (v) {
                if (v != null) setState(() => _method = v);
              },
              child: Column(
                children: paymentProviders
                    .map((provider) => Card(
                          margin:
                              const EdgeInsets.only(bottom: AppTokens.s2),
                          child: RadioListTile<String>(
                            value: provider.id,
                            enabled: provider.enabled,
                            title: Row(
                              children: [
                                Text(provider.label),
                                if (!provider.enabled) ...[
                                  const SizedBox(width: AppTokens.s2),
                                  const AppPill(
                                      label: 'Coming soon',
                                      color: AppTokens.accent),
                                ],
                              ],
                            ),
                            subtitle: Text(provider.description),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: AppTokens.s4),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.s4),
                child: Column(
                  children: [
                    ...cart.lines.map((line) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppTokens.s1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(line.listing.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text(inr(line.listing.price)),
                            ],
                          ),
                        )),
                    if (cart.coupon != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Coupon ${cart.coupon!.code}'),
                          Text('−${inr(cart.coupon!.discountAmount)}'),
                        ],
                      ),
                    const Divider(height: AppTokens.s4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: theme.textTheme.titleMedium),
                        Text(inr(cart.total),
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
              onPressed: _busy ? null : _placeOrder,
              child: Text(_busy
                  ? 'Placing order…'
                  : 'Place order · ${inr(cart.total)}'),
            ),
            const SizedBox(height: AppTokens.s4),
          ],
        ),
      ),
    );
  }
}
