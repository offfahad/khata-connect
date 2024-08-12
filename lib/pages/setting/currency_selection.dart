import 'package:flutter/material.dart';
import 'package:khata_connect/helpers/appLocalizations.dart';
import 'package:khata_connect/providers/stateNotifier.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencySelectionScreen extends StatefulWidget {
  @override
  _CurrencySelectionScreenState createState() =>
      _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends State<CurrencySelectionScreen> {
  String _selectedCurrency = '';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadSelectedCurrency();
  }

  Future<void> _loadSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCurrency = prefs.getString('currency') ?? 'Rs';
    });
  }

  Future<void> _updateCurrency() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currency', _selectedCurrency);
      Provider.of<AppStateNotifier>(context, listen: false)
          .updateCurrency(_selectedCurrency);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('changeCurrency')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  initialValue: _selectedCurrency,
                  decoration:
                      const InputDecoration(labelText: 'Enter Currency Type'),
                  onSaved: (String? value) {
                    _selectedCurrency = value!;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Plase enter a currency';
                    }
                    return null;
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  width: double.infinity, // Full width button
                  height: 50, // Increase height as needed
                  child: ElevatedButton(
                    onPressed: _updateCurrency,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            8.0), // Adjust border radius for rectangular shape
                      ),
                    ),
                    child:
                        Text(AppLocalizations.of(context)!.translate('updateCurrency')),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
