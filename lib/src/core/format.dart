import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// DummyJSON prices are in US dollars; only the number format follows the
/// app language.
String formatPrice(BuildContext context, double value) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return NumberFormat.simpleCurrency(locale: locale, name: 'USD').format(value);
}
