import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:khata_connect/providers/my_theme_provider.dart';
import 'package:khata_connect/services/loadBusinessInfo.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:khata_connect/helpers/appLocalizations.dart';
import 'package:khata_connect/providers/stateNotifier.dart';
import 'package:khata_connect/myTheme.dart';
import 'package:khata_connect/pages/businesses/addBusiness.dart';
import 'package:khata_connect/pages/customers/customers.dart';
import 'package:khata_connect/pages/setting/settings.dart';
import 'package:khata_connect/models/business.dart';
import 'package:khata_connect/blocs/businessBloc.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the notifier before running the app
  final notifier = AppStateNotifier();
  await notifier.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStateNotifier>(
          create: (context) => notifier,
        ),
        ChangeNotifierProvider<MyThemeProvider>(
          create: (context) => MyThemeProvider()..getThemeStatus(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppStateNotifier, MyThemeProvider>(
      builder: (context, appState, themeProvider, child) {
        return MaterialApp(
          title: 'Khata Connect',
          debugShowCheckedModeBanner: false,
          supportedLocales: AppLocalizations.delegate.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: MyTheme.themeData(
              isDarkTheme: themeProvider.themeType, context: context),
          home: const MyHomePage(),
          locale: Locale(appState.appLocale),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final BusinessBloc businessBloc = BusinessBloc();
  int _selectedIndex = 0;
  List<Business?> _businesses = [];
  Business? _selectedBusiness;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await getTheLocale();
    await getAllBusinesses();
    await _loadCurrency(); // Add this line
    setState(() {});
  }

  Future<void> getAllBusinesses() async {
    List<Business?> businesses = await businessBloc.getBusinesss();

    if (businesses.isEmpty) {
      await loadBusinessInfo(context);
      businesses =
          await businessBloc.getBusinesss(); // Refresh list after loading
    }

    final prefs = await SharedPreferences.getInstance();
    int selectedBusinessId = prefs.getInt('selected_business') ?? 0;

    Business? selectedBusiness;
    try {
      selectedBusiness = businesses.firstWhere(
        (business) => business?.id == selectedBusinessId,
      );
    } catch (e) {
      selectedBusiness = null;
    }

    setState(() {
      _businesses = businesses;
      _selectedBusiness = selectedBusiness;
      _isLoading = false;
    });
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = Provider.of<AppStateNotifier>(context, listen: false);
    notifier.updateCurrency(prefs.getString('currency') ?? 'Rs');
  }

  Future<void> getTheLocale() async {
    await fetchLocale(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Stack(
        children: <Widget>[
          Scaffold(
            appBar: AppBar(
              elevation: 0,
              forceMaterialTransparency: true,
              //backgroundColor: Theme.of(context).colorScheme.primary,
              actions: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButton<Business>(
                    value: _selectedBusiness,
                    underline: const SizedBox(),
                    onChanged: (Business? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedBusiness = newValue;
                        });
                        changeSelectedBusiness(context, newValue.id!);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddBusiness(),
                          ),
                        );
                      }
                    },
                    items: _businesses.map<DropdownMenuItem<Business>>(
                      (Business? business) {
                        if (business != null) {
                          return DropdownMenuItem<Business>(
                            value: business,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  business.logo!.isNotEmpty
                                      ? CircleAvatar(
                                          //backgroundColor: Colors.white,
                                          radius: 15,
                                          child: ClipOval(
                                            child: Image.memory(
                                              const Base64Decoder()
                                                  .convert(business.logo!),
                                              width: 30,
                                              height: 30,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      : const SizedBox(width: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    business.companyName!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      //color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return DropdownMenuItem<Business>(
                          value: business,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!
                                    .translate('addRemoveBusiness'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ).toList()
                      ..add(
                        DropdownMenuItem<Business>(
                          value: null,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!
                                    .translate('addRemoveBusiness'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ),
                ),
              ],
            ),
            body: Center(
              child: _isLoading
                  ? LoadingAnimationWidget.fourRotatingDots(
                      color: Colors.black, size: 60)
                  : IndexedStack(
                      index: _selectedIndex,
                      children: [const Customers(), const Settings()],
                    ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: const Icon(Icons.people),
                  label: AppLocalizations.of(context)!.translate('customers'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings),
                  label: AppLocalizations.of(context)!.translate('setting'),
                ),
              ],
              currentIndex: _selectedIndex,
              //selectedItemColor: Colors.redAccent,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
            ),
          ),
          // if (_isLoading)
          //   Center(
          //     child: LoadingAnimationWidget.fourRotatingDots(
          //           color: Colors.black, size: 60),
          //   ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
