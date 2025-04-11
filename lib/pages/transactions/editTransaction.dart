import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khata_connect/helpers/conversion.dart';
import 'package:provider/provider.dart';

import '../../blocs/customerBloc.dart';
import '../../blocs/transactionBloc.dart';
import '../../helpers/appLocalizations.dart';
import '../../providers/stateNotifier.dart';
import '../../models/customer.dart';
import '../../models/transaction.dart';
import 'singleTransaction.dart';

class EditTransaction extends StatefulWidget {
  final Transaction transaction;

  EditTransaction(this.transaction, {Key? key}) : super(key: key);

  @override
  _EditTransactionState createState() => _EditTransactionState();
}

class _EditTransactionState extends State<EditTransaction> {
  String _transType = "credit";
  final TextEditingController _customersField = TextEditingController();
  final TransactionBloc transactionBloc = TransactionBloc();
  final CustomerBloc customerBloc = CustomerBloc();

  String? _comment;
  int? _customerId;
  double? _amount;
  DateTime _date = DateTime.now();
  File? _attachment;
  final picker = ImagePicker();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<AutoCompleteTextFieldState<Customer>> _customerSuggestionKey =
      GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _selectDate(BuildContext context) async {
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

  Future<void> getImageFrom(String from) async {
    XFile? image;
    if (from == 'camera') {
      image = await picker.pickImage(source: ImageSource.camera);
    } else {
      image = await picker.pickImage(source: ImageSource.gallery);
    }

    if (image == null) return;

    ImageProperties properties =
        await FlutterNativeImage.getImageProperties(image.path);
    File rawImage = await FlutterNativeImage.compressImage(image.path,
        quality: 80,
        targetWidth: 800,
        targetHeight: (properties.height! * 800 / properties.width!).round());

    if (rawImage.lengthSync() > 200000) {
      final snackBar = SnackBar(
          content: Row(children: <Widget>[
        const Icon(
          Icons.warning,
          color: Colors.redAccent,
        ),
        Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
            child:
                Text(AppLocalizations.of(context)!.translate('imageSizeError')))
      ]));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }

    setState(() {
      _attachment = rawImage;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Transaction transaction = widget.transaction;
    _customerId = transaction.uid;
    _transType = transaction.ttype!;
    _date = transaction.date!;
  }

  @override
  Widget build(BuildContext context) {
    Transaction argTransaction = widget.transaction;

    return FutureBuilder(
      future: customerBloc.getCustomers(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          List<Customer> customers = snapshot.data;
          if (_customerId != null) {
            customers.forEach((item) {
              if (_customerId == item.id) {
                _customersField.text = item.name!;
              }
            });
          } else {
            customers.forEach((item) {
              if (argTransaction.uid == item.id) {
                _customersField.text = item.name!;
              }
            });
          }

          return Scaffold(
            //backgroundColor: Colors.white,
            key: _scaffoldKey,
            appBar: AppBar(
              elevation: 0.0,
              forceMaterialTransparency: true,
              title: Text(
                AppLocalizations.of(context)!.translate('editTransaction'),
                style: const TextStyle(
                    //color: Colors.black,
                    ),
              ),
              iconTheme: const IconThemeData(
                  //color: Colors.black,
                  ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                updateTransaction(argTransaction);
              },
              icon: const Icon(Icons.check),
              label: Text(
                  AppLocalizations.of(context)!.translate('editTransaction')),
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
                                      : Colors.black38,
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
                                  })
                            ],
                          ),
                          const Padding(padding: EdgeInsets.all(8.0)),
                          Column(
                            children: <Widget>[
                              ActionChip(
                                  backgroundColor: _transType == "payment"
                                      ? Colors.green.shade500
                                      : Colors.black38,
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
                                  })
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      AutoCompleteTextField<Customer>(
                        key: _customerSuggestionKey,
                        clearOnSubmit: false,
                        suggestions: customers,
                        controller: _customersField,
                        decoration: InputDecoration(
                          icon: const Icon(Icons.person),
                          hintText: AppLocalizations.of(context)!
                              .translate('customerNameLabelMeta'),
                          labelText: AppLocalizations.of(context)!
                              .translate('customerNameLabel'),
                        ),
                        itemFilter: (item, query) {
                          _customerId = null;
                          return item.name!
                              .toLowerCase()
                              .startsWith(query.toLowerCase());
                        },
                        itemSorter: (a, b) {
                          return a.name!.compareTo(b.name!);
                        },
                        itemSubmitted: (item) {
                          _customersField.text = item.name!;
                          _customerId = item.id;
                        },
                        itemBuilder: (context, item) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(item.name!),
                              ),
                            ],
                          );
                        },
                      ),
                      TextFormField(
                        initialValue: doubleWithoutDecimalToString(
                            argTransaction.amount!),
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

                          if (double.tryParse(input) == null) {
                            return AppLocalizations.of(context)!
                                .translate('transactionAmountErrorNumber');
                          }
                          return null;
                        },
                        keyboardType: TextInputType.number,
                        onSaved: (input) => _amount = double.parse(input!),
                      ),
                      TextFormField(
                        initialValue: argTransaction.comment,
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
                        child: TextButton(
                          style: TextButton.styleFrom(
                              backgroundColor: Colors.grey),
                          onPressed: () {
                            _selectDate(context);
                          },
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.calendar_today,
                                //color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(formatDate(context, _date)['full']!),
                            ],
                          ),
                        ),
                      ),
                      transactionAttachmentWidget(argTransaction.attachment),
                    ],
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

  Widget transactionAttachmentWidget(String? image) {
    Uint8List? transactionAttachment;
    if (image != null) {
      transactionAttachment = const Base64Decoder().convert(image);
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: _attachment == null
              ? transactionAttachment == null
                  ? const Image(image: AssetImage('assets/images/no_image.jpg'))
                  : Image.memory(transactionAttachment, width: 60)
              : Image.file(_attachment!),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextButton(
            onPressed: () {
              showUploadDialog();
            },
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

  @override
  void dispose() {
    _customersField.dispose();
    super.dispose();
  }

  void updateTransaction(Transaction transaction) async {
    final formState = _formKey.currentState;

    if (formState!.validate()) {
      formState.save();

      if (_customerId == null) {
        final snackBar = SnackBar(
            content: Row(children: <Widget>[
          const Icon(
            Icons.warning,
            color: Colors.redAccent,
          ),
          Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              child: Text(AppLocalizations.of(context)!
                  .translate('customerSelectionLabel')))
        ]));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return;
      }

      if (_attachment != null && _attachment!.lengthSync() > 2000000) {
        final snackBar = SnackBar(
            content: Row(children: <Widget>[
          const Icon(
            Icons.warning,
            color: Colors.redAccent,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
            child:
                Text(AppLocalizations.of(context)!.translate('imageSizeError')),
          )
        ]));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return;
      }

      transaction.ttype = _transType;
      transaction.amount = _amount!;
      transaction.comment = _comment;
      transaction.date = _date;

      if (_attachment != null) {
        String base64Image = base64Encode(_attachment!.readAsBytesSync());
        transaction.attachment = base64Image;
      }

      if (_customerId != null) {
        transaction.uid = _customerId!;
      }

      try {
        await transactionBloc.updateTransaction(transaction);

        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SingleTransaction(transaction.id!),
          ),
        );
      } catch (e) {
        const snackBar = SnackBar(content: Text('Error updating transaction'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }
}
