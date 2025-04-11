import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:khata_connect/providers/stateNotifier.dart';
import 'package:provider/provider.dart';

Map<String, String> formatDate(BuildContext context, DateTime date) {
  String formatted = DateFormat("dd, MMMM yyyy").format(date);
  String day = DateFormat("dd").format(date);
  String month = DateFormat("MMM").format(date);
  String year = DateFormat("yyyy").format(date);
  return {"full": formatted, "day": day, "month": month, "year": year};
}

String amountFormat(BuildContext context, double n) {
  String currency = Provider.of<AppStateNotifier>(context).currency;
  num x = n % 1 == 0 ? n.toInt() : n;

  // Use standard Dart number formatting with currency symbol
  return '$currency${x.toStringAsFixed(x % 1 == 0 ? 0 : 2)}';
}

String doubleWithoutDecimalToString(double val) {
  num x = val % 1 == 0 ? val.toInt() : val;
  return x.toString();
}
