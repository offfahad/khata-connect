import 'dart:convert';
import 'dart:io';

import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../blocs/customerBloc.dart';
import '../../blocs/transactionBloc.dart';
import '../../helpers/appLocalizations.dart';
import '../../helpers/conversion.dart';
import '../../providers/stateNotifier.dart';
import '../../models/customer.dart';
import '../../models/transaction.dart';
import '../customers/singleCustomer.dart';

class AddTransaction extends StatefulWidget {
  final Customer customer;
  final String transType;

  AddTransaction(this.customer, this.transType, {Key? key}) : super(key: key);

  @override
  _AddTransactionState createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  String _transType = "credit";
  AutoCompleteTextField<Customer>? searchTextField;

  final TransactionBloc transactionBloc = TransactionBloc();
  final CustomerBloc customerBloc = CustomerBloc();

  String? _comment, _customerName;
  int? _customerId;
  double? _amount;
  DateTime _date = DateTime.now();
  File? _attachment;
  final picker = ImagePicker();

  Transaction transaction = Transaction();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<AutoCompleteTextFieldState<Customer>> _customerSuggestionKey =
      GlobalKey();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _transType = widget.transType;
    _customerId = widget.customer.id;
    _customerName = widget.customer.name;

    _comment = _transType == "credit" ? "Credit given" : "Payment received";
  }

  Future<void> _selectDate(BuildContext context) async {
    String lang =
        Provider.of<AppStateNotifier>(context, listen: false).appLocale;

    if (lang == 'ne') {
      NepaliDateTime? _nepaliDateTime = await showMaterialDatePicker(
        context: context,
        initialDate: _date.toNepaliDateTime(),
        firstDate: NepaliDateTime(2000),
        lastDate: NepaliDateTime(2090),
        initialDatePickerMode: DatePickerMode.day,
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: Theme.of(context).colorScheme.secondary,
                onPrimary: Colors.white,
                surface: Colors.green.shade500,
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: Theme.of(context).primaryColor,
            ),
            child: child!,
          );
        },
      );

      if (_nepaliDateTime != null) {
        setState(() {
          _date =
              _nepaliDateTime.toDateTime().subtract(const Duration(days: 1));
        });
      }
    } else {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2030, 8),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: Theme.of(context).colorScheme.secondary,
                onPrimary: Colors.white,
                surface: Colors.green.shade500,
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: Theme.of(context).primaryColor,
            ),
            child: child!,
          );
        },
      );
      if (picked != null && picked != _date) {
        setState(() {
          _date = picked;
        });
      }
    }
  }

  Future<void> getImageFrom(String from) async {
    final XFile? image = from == 'camera'
        ? await picker.pickImage(source: ImageSource.camera)
        : await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    ImageProperties properties =
        await FlutterNativeImage.getImageProperties(image.path);
    File rawImage = await FlutterNativeImage.compressImage(
      image.path,
      quality: 80,
      targetWidth: 800,
      targetHeight: (properties.height! * 800 / properties.width!).round(),
    );

    if (rawImage.lengthSync() > 200000) {
      final snackBar = SnackBar(
        content: Row(children: <Widget>[
          const Icon(Icons.warning, color: Colors.redAccent),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
            child:
                Text(AppLocalizations.of(context)!.translate('imageSizeError')),
          ),
        ]),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }

    setState(() {
      _attachment = rawImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: customerBloc.getCustomers(),
      builder: (BuildContext context, AsyncSnapshot<List<Customer>> snapshot) {
        if (snapshot.hasData) {
          final List<Customer> customers = snapshot.data!;

          return SafeArea(
            child: Scaffold(
              key: _scaffoldKey,
              //backgroundColor: Colors.white,
              appBar: AppBar(
                elevation: 0.0,
                backgroundColor: Colors.transparent,
                title: Text(
                  AppLocalizations.of(context)!.translate('addTransaction'),
                  //style: const TextStyle(color: Colors.black),
                ),
                //iconTheme: const IconThemeData(color: Colors.black),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: addTransaction,
                icon: const Icon(Icons.check),
                label: Text(
                    AppLocalizations.of(context)!.translate('addTransaction')),
                heroTag: _transType,
              ),
              body: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 48),
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Column(
                              children: <Widget>[
                                ActionChip(
                                  backgroundColor: _transType == "credit"
                                      ? Colors.green.shade500
                                      : Colors.grey,
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.send,
                                      color: Colors.blueAccent,
                                      size: 16.0,
                                    ),
                                  ),
                                  label: Text(AppLocalizations.of(context)!
                                      .translate('creditGiven')),
                                  onPressed: () {
                                    setState(() {
                                      _transType = "credit";
                                    });
                                  },
                                )
                              ],
                            ),
                            const Padding(padding: EdgeInsets.all(8.0)),
                            Column(
                              children: <Widget>[
                                ActionChip(
                                  backgroundColor: _transType == "payment"
                                      ? Colors.green.shade500
                                      : Colors.grey,
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.receipt,
                                      color: Colors.redAccent,
                                      size: 16.0,
                                    ),
                                  ),
                                  label: Text(AppLocalizations.of(context)!
                                      .translate('paymentReceived')),
                                  onPressed: () {
                                    setState(() {
                                      _transType = "payment";
                                    });
                                  },
                                )
                              ],
                            ),
                          ],
                        ),
                        widget.customer != null
                            ? Row(
                                children: <Widget>[
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(4, 16, 4, 16),
                                    child: Text(_customerName!,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: 18)),
                                  ),
                                ],
                              )
                            : AutoCompleteTextField<Customer>(
                                key: _customerSuggestionKey,
                                clearOnSubmit: false,
                                suggestions: customers,
                                decoration: InputDecoration(
                                  icon: const Icon(Icons.person),
                                  hintText: AppLocalizations.of(context)!
                                      .translate('customerNameLabelMeta'),
                                  labelText: AppLocalizations.of(context)!
                                      .translate('customerNameLabel'),
                                ),
                                itemFilter: (item, query) {
                                  _customerName = query;
                                  _customerId = null;
                                  return item.name!
                                      .toLowerCase()
                                      .startsWith(query.toLowerCase());
                                },
                                itemSorter: (a, b) => a.name!.compareTo(b.name!),
                                itemSubmitted: (item) {
                                  setState(() {
                                    searchTextField?.textField!.controller?.text =
                                        item.name!;
                                    _customerId = item.id;
                                  });
                                },
                                itemBuilder: (context, item) => Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(item.name!),
                                    ),
                                  ],
                                ),
                              ),
                        TextFormField(
                          autofocus: true,
                          decoration: InputDecoration(
                            icon: const Icon(Icons.monetization_on),
                            hintText: AppLocalizations.of(context)!
                                .translate('transactionAmountLabelMeta'),
                            labelText: AppLocalizations.of(context)!
                                .translate('transactionAmountLabel'),
                          ),
                          validator: (input) {
                            if (input == null || input.isEmpty) {
                              return AppLocalizations.of(context)!
                                  .translate('transactionAmountError');
                            }
                            if (double.tryParse(input) == null ||
                                double.parse(input) <= 0) {
                              return AppLocalizations.of(context)!
                                  .translate('transactionAmountErrorNumber');
                            }
                            return null;
                          },
                          keyboardType: TextInputType.number,
                          onSaved: (input) => _amount = double.parse(input!),
                        ),
                        TextFormField(
                          initialValue: _comment,
                          decoration: InputDecoration(
                            icon: const Icon(Icons.comment),
                            hintText: AppLocalizations.of(context)!
                                .translate('transactionCommentLabelMeta'),
                            labelText: AppLocalizations.of(context)!
                                .translate('transactionCommentLabel'),
                          ),
                          maxLines: 3,
                          onSaved: (input) => _comment = input,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 24, 8, 24),
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey,
                            ),
                            icon: const Icon(
                              Icons.calendar_today,
                              //color: Colors.grey.shade600,
                            ),
                            label: Text(formatDate(context, _date)['full']!),
                            onPressed: () => _selectDate(context),
                          ),
                        ),
                        transactionAttachmentWidget(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget transactionAttachmentWidget() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _attachment == null
              ? Image.asset('assets/images/no_image.jpg')
              : Image.file(_attachment!),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextButton(
            onPressed: showUploadDialog,
            child: Text(AppLocalizations.of(context)!
                .translate('transactionImageLabel')),
          ),
        ),
      ],
    );
  }

  void showUploadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(
              AppLocalizations.of(context)!.translate('transactionImageLabel')),
          children: <Widget>[
            SimpleDialogOption(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(AppLocalizations.of(context)!
                    .translate('uploadFromCamera')),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                getImageFrom('camera');
              },
            ),
            SimpleDialogOption(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(AppLocalizations.of(context)!
                    .translate('uploadFromGallery')),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                getImageFrom('gallery');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> addTransaction() async {
    final formState = _formKey.currentState;

    if (formState?.validate() ?? false) {
      formState?.save();

      if (_customerId == null) {
        final snackBar = SnackBar(
          content: Row(
            children: <Widget>[
              const Icon(Icons.warning, color: Colors.redAccent),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                child: Text(AppLocalizations.of(context)!
                    .translate('customerSelectionLabel')),
              ),
            ],
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return;
      }

      if (_attachment != null && _attachment!.lengthSync() > 2000000) {
        final snackBar = SnackBar(
          content: Row(
            children: <Widget>[
              const Icon(Icons.warning, color: Colors.redAccent),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                child: Text(
                    AppLocalizations.of(context)!.translate('imageSizeError')),
              ),
            ],
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      int selectedBusinessId = prefs.getInt('selected_business') ?? 0;

      transaction
        ..businessId = selectedBusinessId
        ..ttype = _transType
        ..amount = _amount!
        ..comment = _comment
        ..date = _date
        ..attachment = _attachment != null
            ? base64Encode(_attachment!.readAsBytesSync())
            : null
        ..uid = _customerId;

      try {
        await transactionBloc.addTransaction(transaction);
        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SingleCustomer(_customerId!),
          ),
        );
      } catch (e) {
        print('Error adding transaction: $e');
        final snackBar = const SnackBar(
          content: Row(
            children: <Widget>[
              Icon(Icons.error, color: Colors.redAccent),
              Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 0, 0),
                child: Text('Failed to add transaction. Please try again.'),
              ),
            ],
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
