import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:khata_connect/providers/stateNotifier.dart';
import 'package:khata_connect/pages/customers/addCustomer.dart';
import 'package:khata_connect/pages/customers/singleCustomer.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../blocs/customerBloc.dart';
import '../../blocs/transactionBloc.dart';
import '../../helpers/appLocalizations.dart';
import '../../helpers/conversion.dart';
import '../../helpers/generateCustomersPdf.dart';
import '../../models/customer.dart';

class Customers extends StatefulWidget {
  const Customers({Key? key}) : super(key: key);

  @override
  _CustomersState createState() => _CustomersState();
}

class _CustomersState extends State<Customers> {
  final TransactionBloc transactionBloc = TransactionBloc();
  final CustomerBloc _customerBloc = CustomerBloc();
  final TextEditingController _searchInputController = TextEditingController();
  bool _absorbing = false;
  String _searchText = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Container(
            decoration: const BoxDecoration(
                //color: Colors.white,
                ),
            child: Column(
              children: [
                Container(
                  alignment: Alignment.center,
                  height: 120,
                  decoration: const BoxDecoration(
                      //color: Theme.of(context).primaryColor,
                      ),
                  child: Column(
                    children: [
                      // Container(
                      //   padding: const EdgeInsets.fromLTRB(16, 10, 0, 0),
                      //   child: Row(
                      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //     children: <Widget>[
                      //       getTotalGivenToCustomersWidget(),
                      //       getTotalToReceiveFromCustomersWidget(),
                      //       IconButton(
                      //         icon: const Icon(Icons.picture_as_pdf),
                      //         color: Colors.red,
                      //         onPressed: generatePdf,
                      //       )
                      //     ],
                      //   ),
                      // ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(8, 15, 8, 0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 06,
                          semanticContainer: true,
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                            child: TextField(
                              controller: _searchInputController,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.translate(
                                    'searchCustomers'), // Replace with AppLocalizations
                                suffixIcon: _searchText.isEmpty
                                    ? const Icon(Icons.search)
                                    : IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          _searchInputController.clear();
                                          setState(() {
                                            _searchText = "";
                                          });
                                        },
                                      ),
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              onChanged: (text) {
                                setState(() {
                                  _searchText = text;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(25.0),
                        topLeft: Radius.circular(25.0),
                      ),
                      color: Colors.white,
                    ),
                    child: getCustomersList(),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddCustomer()),
              );
              setState(() {});
            },
            icon: const Icon(
              Icons.add,
            ),
            label: Text(AppLocalizations.of(context)!
                .translate('addCustomer')), // Replace with AppLocalizations
          ),
        ),
        if (_absorbing)
          AbsorbPointer(
            absorbing: _absorbing,
            child: Center(
              child: LoadingAnimationWidget.fourRotatingDots(
                color: Theme.of(context).colorScheme.secondary,
                size: 60,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> generatePdf() async {
    setState(() {
      _absorbing = true;
    });
    try {
      Uint8List pdf = await generateCustomerPdf();
      final dir = await getExternalStorageDirectory();
      final file = File('${dir?.path}/report.pdf');
      await file.writeAsBytes(pdf);
      OpenFile.open(file.path);
    } catch (e) {
      // Handle errors (e.g., show a snackbar)
      print('Error generating PDF: $e');
    } finally {
      setState(() {
        _absorbing = false;
      });
    }
  }

  Widget getCustomersList() {
    return Consumer<AppStateNotifier>(builder: (context, provider, child) {
      return FutureBuilder<List<Customer>>(
        future: _customerBloc.getCustomers(query: _searchText),
        builder:
            (BuildContext context, AsyncSnapshot<List<Customer>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Unknown Error."));
          }
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 60),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, itemIndex) {
                final customer = snapshot.data![itemIndex];
                final customerImage = customer.image != null
                    ? base64Decode(customer.image!)
                    : null;

                return Column(
                  children: <Widget>[
                    ListTile(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SingleCustomer(customer.id!),
                          ),
                        );
                        setState(() {});
                      },
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: customerImage != null
                            ? Colors.transparent
                            : Colors.purple.shade500,
                        child: customerImage != null
                            ? ClipOval(
                                child: Image.memory(
                                  customerImage,
                                  height: 48,
                                  width: 48,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.person,
                                color: Colors.purple, size: 24.0),
                      ),
                      title: Text(
                        customer.name!,
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.phone,
                            size: 12.0,
                            color: Colors.black87,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                            child: Text(
                              customer.phone!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      trailing:
                          getCustomerTransactionsTotalWidget(customer.id!),
                    ),
                    if (itemIndex < snapshot.data!.length - 1)
                      const Divider(color: Colors.grey, height: 2),
                  ],
                );
              },
            );
          }
          return const Center(child: Text("No customers found."));
        },
      );
    });
  }

  Widget getCustomerTransactionsTotalWidget(int cid) {
    return FutureBuilder<double>(
      future: transactionBloc.getCustomerTransactionsTotal(cid),
      builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }
        if (snapshot.hasError) {
          return const SizedBox();
        }
        if (snapshot.hasData) {
          final total = snapshot.data!;
          final ttype = total.isNegative ? "credit" : "payment";
          return SizedBox(
            width: 80, // Set a fixed width for the trailing widget
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      amountFormat(context, total.abs()),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: ttype == 'payment' ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    ttype == "credit"
                        ? AppLocalizations.of(context)!.translate('given')
                        : AppLocalizations.of(context)!.translate(
                            'received'), // Replace with AppLocalizations
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget getBusinessTransactionsTotalWidget() {
    final bid = Provider.of<AppStateNotifier>(context).selectedBusiness;
    if (bid == null) return const SizedBox();

    return FutureBuilder<double>(
      future: transactionBloc
          .getBusinessTransactionsTotal(bid), // Ensure `bid.id` is used
      builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Better to show a progress indicator
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}'); // Display error if present
        }
        if (snapshot.hasData) {
          final total = snapshot.data!;
          final ttype = total.isNegative ? "credit" : "payment";
          return Row(
            children: <Widget>[
              Text(
                amountFormat(
                    context, total.abs()), // Ensure `amountFormat` is defined
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: ttype == 'payment' ? Colors.green : Colors.red,
                ),
              ),
            ],
          );
        }
        return const SizedBox(); // Handle case when no data
      },
    );
  }

  Widget getTotalGivenToCustomersWidget() {
    final bid = Provider.of<AppStateNotifier>(context).selectedBusiness;
    if (bid == null) return const SizedBox();

    return FutureBuilder<double>(
      future: transactionBloc.getTotalGivenToCustomers(bid),
      builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Better to show a progress indicator
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}'); // Display error if present
        }
        if (snapshot.hasData) {
          final totalGiven = snapshot.data!;
          return Row(
            children: <Widget>[
              Text(
                amountFormat(
                    context, totalGiven), // Ensure `amountFormat` is defined
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
              // Text(
              //   ' Total Given to Customers',
              //   style: TextStyle(
              //     fontSize: 16,
              //     color: Colors.black,
              //   ),
              // ),
            ],
          );
        }
        return const SizedBox(); // Handle case when no data
      },
    );
  }

  Widget getTotalToReceiveFromCustomersWidget() {
    final bid = Provider.of<AppStateNotifier>(context).selectedBusiness;
    if (bid == null) return const SizedBox();

    return FutureBuilder<double>(
      future: transactionBloc.getTotalToReceiveFromCustomers(bid),
      builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Better to show a progress indicator
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}'); // Display error if present
        }
        if (snapshot.hasData) {
          final totalToReceive = snapshot.data!;
          return Row(
            children: <Widget>[
              Text(
                amountFormat(context,
                    totalToReceive), // Ensure `amountFormat` is defined
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
              // Text(
              //   ' Total to Receive from Customers',
              //   style: TextStyle(
              //     fontSize: 16,
              //     color: Colors.black,
              //   ),
              // ),
            ],
          );
        }
        return const SizedBox(); // Handle case when no data
      },
    );
  }

  @override
  void dispose() {
    _searchInputController.dispose();
    super.dispose();
  }
}
