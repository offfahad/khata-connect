import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/appLocalizations.dart';

class AppStateNotifier extends ChangeNotifier {
  bool isDarkMode = false;
  int selectedBusiness = 0;
  String appLocale = "en";
  String currency = "Rs";
  String calendar = "en";

  void updateLocale(String locale) {
    appLocale = locale;
    notifyListeners();
  }

  void updateSelectedBusiness(int bid) {
    selectedBusiness = bid;
    notifyListeners();
  }

  void updateCurrency(String currency) {
    this.currency = currency;
    notifyListeners();
  }

  void updateCalendar(String calendar) {
    this.calendar = calendar;
    notifyListeners();
  }
}

Future<void> fetchLocale(BuildContext context) async {
  var prefs = await SharedPreferences.getInstance();
  String code = prefs.getString('language_code') ?? "en";
  Provider.of<AppStateNotifier>(context, listen: false).updateLocale(code);
  AppLocalizations.delegate.load(Locale(code));
}

Future<void> changeLanguage(BuildContext context, String lang) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'language_code';

  // Update locale and localization delegate
  Provider.of<AppStateNotifier>(context, listen: false).updateLocale(lang);
  Locale appLocale = Locale(lang);
  AppLocalizations.delegate.load(appLocale);

  // Save to shared preferences
  await prefs.setString(key, lang);
}

Future<void> changeSelectedBusiness(BuildContext context, int id) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'selected_business';

  // Save selected business ID to shared preferences
  await prefs.setInt(key, id);

  // Update app state
  Provider.of<AppStateNotifier>(context, listen: false)
      .updateSelectedBusiness(id);
}

Future<void> changeCurrency(BuildContext context, String currency) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'currency';

  // Save currency to shared preferences
  await prefs.setString(key, currency);

  // Update app state
  Provider.of<AppStateNotifier>(context, listen: false)
      .updateCurrency(currency);
}

Future<void> changeCalendar(BuildContext context, String calendar) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'calendar';

  // Save calendar to shared preferences
  await prefs.setString(key, calendar);

  // Update app state
  Provider.of<AppStateNotifier>(context, listen: false)
      .updateCalendar(calendar);
}
