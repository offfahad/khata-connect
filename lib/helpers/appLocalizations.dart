import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const AppLocalizationsDelegate delegate = AppLocalizationsDelegate();

  // Ensure this is a getter method for appLocale if you plan to use it
  // You might want to remove or modify this if it’s not used
  String get appLocale => locale.toString();

  late Map<String, String> _localizedStrings;

  Future<bool> load() async {
    try {
      String jsonString =
          await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });

      return true;
    } catch (e) {
      // Handle errors or fallback
      print("Error loading localization file: $e");
      return false;
    }
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale('en', ''),
      Locale('ur', ''),
      //Locale('ne', ''),
    ];
  }

  @override
  bool isSupported(Locale locale) {
    return supportedLocales.any((supportedLocale) =>
        supportedLocale.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
