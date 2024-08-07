import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:khata_connect/helpers/conversion.dart';
import '../../blocs/customerBloc.dart';
import '../../blocs/transactionBloc.dart';
import '../../helpers/appLocalizations.dart';
import '../../models/customer.dart';
import '../../models/transaction.dart';
import 'editTransaction.dart';
import '../customers/singleCustomer.dart';

class SingleTransaction extends StatefulWidget {
  final int transactionId;

  SingleTransaction(this.transactionId, {Key? key}) : super(key: key);

  @override
  _SingleTransactionState createState() => _SingleTransactionState();
}

class _SingleTransactionState extends State<SingleTransaction> {
  final TransactionBloc transactionBloc = TransactionBloc();
  final CustomerBloc customerBloc = CustomerBloc();

  void _showDeleteDialog(Transaction transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              AppLocalizations.of(context)!.translate('deleteTransaction')),
          content: Text(AppLocalizations.of(context)!
              .translate('deleteTransactionLabel')),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.translate('closeText')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                AppLocalizations.of(context)!.translate('deleteText'),
                style: const TextStyle(
                    //color: Colors.white,
                    ),
              ),
              onPressed: () {
                transactionBloc.deleteTransactionById(transaction.id!);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SingleCustomer(transaction.uid!),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Transaction>(
      future: transactionBloc.getTransaction(widget.transactionId),
      builder: (BuildContext context, AsyncSnapshot<Transaction> snapshot) {
        if (snapshot.hasData) {
          Transaction transaction = snapshot.data!;

          Uint8List? transactionAttachment;
          if (transaction.attachment != null) {
            transactionAttachment =
                const Base64Decoder().convert(transaction.attachment!);
          }

          return SafeArea(
            child: Scaffold(
              appBar: AppBar(
                elevation: 0.0,
                backgroundColor: Colors.transparent,
                title: null,
                iconTheme: const IconThemeData(
                    //color: Colors.black,
                    ),
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.edit,
                        size: 20.0, color: Colors.purple),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditTransaction(transaction),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.delete, size: 20.0, color: Colors.red),
                    onPressed: () {
                      _showDeleteDialog(transaction);
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              getTransactionCustomer(transaction),
                              SizedBox(
                                height: 20,
                              ),
                              Row(
                                children: <Widget>[
                                  transaction.ttype == 'credit'
                                      ? Chip(
                                          label: Text(
                                              AppLocalizations.of(context)!
                                                  .translate('creditGiven')),
                                          //backgroundColor:
                                          //   Colors.orange.shade100,
                                          avatar: Icon(Icons.arrow_upward,
                                              color: Colors.orange.shade900,
                                              size: 20.0),
                                        )
                                      : Chip(
                                          label: Text(AppLocalizations.of(
                                                  context)!
                                              .translate('paymentReceived')),
                                          //backgroundColor:
                                          //  Colors.orange.shade100,
                                          avatar: Icon(Icons.arrow_downward,
                                              color: Colors.green.shade900,
                                              size: 20.0),
                                        ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(16, 0, 0, 0),
                                    child: Text(
                                      amountFormat(
                                          context, transaction.amount!.abs()),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              Divider(
                                //color: Colors.grey.shade300,
                                height: 36,
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                child: Text(
                                  transaction.comment!,
                                  softWrap: true,
                                  textAlign: TextAlign.left,
                                  
                                  style: const TextStyle(
                                    //color: Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 36, 0, 36),
                                    child: transactionAttachment != null
                                        ? Image.memory(transactionAttachment!,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.8,
                                            fit: BoxFit.cover)
                                        : Container(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget getTransactionCustomer(Transaction transaction) {
    return FutureBuilder<Customer>(
      future: customerBloc.getCustomer(transaction.uid!),
      builder: (BuildContext context, AsyncSnapshot<Customer> snapshot) {
        if (snapshot.hasData) {
          Customer customer = snapshot.data!;
          return Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 12, 4),
                child: CircleAvatar(
                  backgroundColor: Colors.purple.shade500,
                  child: Icon(Icons.person,
                      color: Colors.purple.shade100, size: 20.0),
                ),
              ),
              Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: Text(customer.name!,
                        style: const TextStyle(
                          //color: Colors.black87,
                          fontSize: 18,
                        )),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                    child: Text(
                      "${transaction.date!.day}/${transaction.date!.month}/${transaction.date!.year}",
                      style: const TextStyle(
                        //color: Colors.black45,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              )
            ],
          );
        }
        return Container();
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
