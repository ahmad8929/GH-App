import 'models/models.dart';

/// Payment abstraction. Checkout creates the order first (backend marks it
/// `unpaid`), then hands it to the selected provider. A real gateway slots in
/// by adding a provider here — the checkout flow does not change.
class PaymentResult {
  final String status; // unpaid | paid
  final String? reference;
  const PaymentResult(this.status, {this.reference});
}

abstract class PaymentProvider {
  String get id;
  String get label;
  String get description;
  bool get enabled;
  Future<PaymentResult> pay(Order order);
}

class PayOnDelivery implements PaymentProvider {
  @override
  String get id => 'cod';
  @override
  String get label => 'Pay on delivery';
  @override
  String get description => 'Pay in cash or UPI when your order arrives.';
  @override
  bool get enabled => true;
  @override
  Future<PaymentResult> pay(Order order) async => const PaymentResult('unpaid');
}

class OnlinePayment implements PaymentProvider {
  @override
  String get id => 'online';
  @override
  String get label => 'Pay online';
  @override
  String get description => 'Cards, UPI, netbanking — coming soon.';
  @override
  bool get enabled => false;
  @override
  Future<PaymentResult> pay(Order order) async =>
      throw UnsupportedError('Online payments are not available yet');
}

final paymentProviders = <PaymentProvider>[PayOnDelivery(), OnlinePayment()];
