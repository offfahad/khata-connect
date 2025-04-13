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
  const Customers({super.key});

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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          body: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
            ),
            child: Column(
              children: [
                Container(
                  alignment: Alignment.center,
                  height: 100,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(8, 15, 8, 0),
                        child: Card(
                          color: isDarkMode
                              ? const Color(0xFF444654)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 6,
                          semanticContainer: true,
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                            child: TextField(
                              controller: _searchInputController,
                              style:
                                  TextStyle(color: theme.colorScheme.onSurface),
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!
                                    .translate('searchCustomers'),
                                labelStyle: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7)),
                                suffixIcon: _searchText.isEmpty
                                    ? Icon(Icons.search,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.7))
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
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(25.0),
                        topLeft: Radius.circular(25.0),
                      ),
                      color: theme.cardColor,
                    ),
                    child: getCustomersList(),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: theme.primaryColor,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddCustomer()),
              );
              setState(() {});
            },
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            label: Text(
              AppLocalizations.of(context)!.translate('addCustomer'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        if (_absorbing)
          AbsorbPointer(
            absorbing: _absorbing,
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: LoadingAnimationWidget.fourRotatingDots(
                  color: theme.colorScheme.secondary,
                  size: 60,
                ),
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
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    } finally {
      setState(() {
        _absorbing = false;
      });
    }
  }

  Widget getCustomersList() {
    final theme = Theme.of(context);

    return Consumer<AppStateNotifier>(builder: (context, provider, child) {
      return FutureBuilder<List<Customer>>(
        future: _customerBloc.getCustomers(query: _searchText),
        builder:
            (BuildContext context, AsyncSnapshot<List<Customer>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: theme.primaryColor));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text("Unknown Error.",
                    style: TextStyle(color: theme.colorScheme.error)));
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
                            : theme.primaryColor,
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
                                color: Colors.white, size: 24.0),
                      ),
                      title: Text(
                        customer.name!,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Row(
                        children: <Widget>[
                          Icon(
                            Icons.phone,
                            size: 12.0,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                            child: Text(
                              customer.phone!,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 100,
                          maxWidth: MediaQuery.of(context).size.width * 0.3,
                        ),
                        child: getCustomerTransactionsTotalWidget(customer.id!),
                      ),
                    ),
                    if (itemIndex < snapshot.data!.length - 1)
                      Divider(
                        color: theme.dividerColor,
                        height: 1,
                        thickness: 0.5,
                      ),
                  ],
                );
              },
            );
          }
          return Center(
            child: Text(
              "No customers found.",
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
          );
        },
      );
    });
  }

  Widget getCustomerTransactionsTotalWidget(int cid) {
    final theme = Theme.of(context);

    return FutureBuilder<double>(
      future: transactionBloc.getCustomerTransactionsTotal(cid),
      builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: theme.dividerColor,
              color: theme.primaryColor,
            ),
          );
        }
        if (snapshot.hasError) {
          return const SizedBox();
        }
        if (snapshot.hasData) {
          final total = snapshot.data!;
          final ttype = total.isNegative ? "credit" : "payment";
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    amountFormat(context, total.abs()),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: ttype == 'payment' ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    ttype == "credit"
                        ? AppLocalizations.of(context)!.translate('given')
                        : AppLocalizations.of(context)!.translate('received'),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
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
      future: transactionBloc.getBusinessTransactionsTotal(bid),
      builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(
              color: Theme.of(context).primaryColor);
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error));
        }
        if (snapshot.hasData) {
          final total = snapshot.data!;
          final ttype = total.isNegative ? "credit" : "payment";
          return FittedBox(
            child: Text(
              amountFormat(context, total.abs()),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: ttype == 'payment' ? Colors.green : Colors.red,
              ),
            ),
          );
        }
        return const SizedBox();
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
          return CircularProgressIndicator(
              color: Theme.of(context).primaryColor);
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error));
        }
        if (snapshot.hasData) {
          final totalGiven = snapshot.data!;
          return FittedBox(
            child: Text(
              amountFormat(context, totalGiven),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          );
        }
        return const SizedBox();
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
          return CircularProgressIndicator(
              color: Theme.of(context).primaryColor);
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error));
        }
        if (snapshot.hasData) {
          final totalToReceive = snapshot.data!;
          return FittedBox(
            child: Text(
              amountFormat(context, totalToReceive),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  @override
  void dispose() {
    _searchInputController.dispose();
    super.dispose();
  }
}
