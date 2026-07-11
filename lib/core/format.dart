import 'package:intl/intl.dart';

final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _inrPaise =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
final _date = DateFormat('d MMM yyyy');

String inr(Object? value) {
  if (value == null) return 'Free';
  final amount = value is num ? value.toDouble() : double.tryParse('$value');
  if (amount == null) return '—';
  if (amount == 0) return 'Free';
  // Whole rupees stay clean (₹280); fractional unit prices keep their paise
  // (₹16.50) instead of silently rounding to ₹17.
  final isWhole = amount == amount.roundToDouble();
  return isWhole ? _inr.format(amount) : _inrPaise.format(amount);
}

String formatDate(DateTime? date) => date == null ? '—' : _date.format(date);

const conditionLabels = <String, String>{
  'new': 'Brand new',
  'like_new': 'Like new',
  'good': 'Good',
  'fair': 'Fair',
  'poor': 'Well loved',
};

const listingTypeLabels = <String, String>{
  'sale': 'For sale',
  'exchange': 'Exchange',
  'donate': 'Free',
};

const orderItemStatusLabels = <String, String>{
  'pending': 'Pending',
  'confirmed': 'Confirmed',
  'packed': 'Packed',
  'assigned': 'Assigned',
  'in_transit': 'On the way',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
  'returned': 'Returned',
};

String humanize(String value) => value.replaceAll('_', ' ');
