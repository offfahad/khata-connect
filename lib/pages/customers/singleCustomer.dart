import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:khata_connect/helpers/conversion.dart';
import 'package:khata_connect/helpers/generateCustomerTransaction.dart';
import 'package:khata_connect/main.dart';
import 'package:khata_connect/pages/customers/editCustomer.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:khata_connect/helpers/appLocalizations.dart';
import 'package:khata_connect/models/customer.dart';
import 'package:khata_connect/models/transaction.dart';
import 'package:khata_connect/pages/transactions/addTransaction.dart';
import 'package:khata_connect/pages/transactions/singleTransaction.dart';
import 'package:khata_connect/blocs/customerBloc.dart';
import 'package:khata_connect/blocs/transactionBloc.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class SingleCustomer extends StatefulWidget {
  final int customerId;

  const SingleCustomer(this.customerId, {super.key});

  @override
  State<SingleCustomer> createState() => _SingleCustomerState();
}

class _SingleCustomerState extends State<SingleCustomer> {
  final CustomerBloc customerBloc = CustomerBloc();
  final TransactionBloc transactionBloc = TransactionBloc();
  bool _absorbing = false;

  void _showDeleteDialog(Customer customer) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.translate('deleteCustomer'),
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: Text(
            AppLocalizations.of(context)!.translate('deleteCustomerLabel'),
            style:
                TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
          ),
          backgroundColor: theme.cardColor,
          actions: <Widget>[
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.translate('closeText'),
                style: TextStyle(color: theme.colorScheme.secondary),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                AppLocalizations.of(context)!.translate('deleteText'),
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: () {
                customerBloc.deleteCustomerById(customer.id!);
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> generatePdf() async {
    if (!mounted) return;

    setState(() {
      _absorbing = true;
    });

    try {
      final file = await buildTransactionPdf();
      if (file != null) {
        await OpenFile.open(file.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _absorbing = false;
        });
      }
    }
  }

  Future<File?> buildTransactionPdf() async {
    try {
      // Generate the PDF bytes
      Uint8List pdfBytes =
          await generateCustomerTransactionPdf(widget.customerId);

      // Save to temporary directory (works on all platforms)
      final output = await getTemporaryDirectory();
      final file = File(
          '${output.path}/transaction_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(pdfBytes);
      return file;
    } catch (e) {
      print('PDF generation error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return FutureBuilder<Customer>(
      future: customerBloc.getCustomer(widget.customerId),
      builder: (BuildContext context, AsyncSnapshot<Customer> snapshot) {
        if (snapshot.hasData) {
          Customer customer = snapshot.data!;
          Uint8List? customerImage;
          if (customer.image != null && customer.image!.isNotEmpty) {
            customerImage = const Base64Decoder().convert(customer.image!);
          }

          return Stack(
            children: [
              Scaffold(
                persistentFooterButtons: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          // Add Expanded here
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: FloatingActionButton.extended(
                              icon: const Icon(Icons.arrow_upward, size: 18),
                              backgroundColor: Colors.red.shade600,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddTransaction(
                                      customer: customer,
                                      transType: 'credit',
                                    ),
                                  ),
                                );
                              },
                              label: Text(
                                AppLocalizations.of(context)!
                                    .translate('creditGiven'),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                              heroTag: "credit",
                            ),
                          ),
                        ),
                        Expanded(
                          // Add Expanded here
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: FloatingActionButton.extended(
                              icon: const Icon(Icons.arrow_downward, size: 18),
                              backgroundColor: theme.primaryColor,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddTransaction(
                                      customer: customer,
                                      transType: "payment",
                                    ),
                                  ),
                                );
                              },
                              label: Text(
                                AppLocalizations.of(context)!
                                    .translate('paymentReceived'),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                              heroTag: "payment",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                resizeToAvoidBottomInset: true,
                appBar: AppBar(
                  elevation: 0,
                  forceMaterialTransparency: true,
                  iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
                  actions: <Widget>[
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        size: 20.0,
                        color: theme.colorScheme.secondary,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditCustomer(customer),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 20.0,
                        color: Colors.red,
                      ),
                      onPressed: () => _showDeleteDialog(customer),
                    ),
                  ],
                ),
                body: Column(
                  children: <Widget>[
                    // Customer Header Section
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              customerImage != null
                                  ? CircleAvatar(
                                      radius: 36.0,
                                      backgroundColor: Colors.transparent,
                                      child: ClipOval(
                                        child: Image.memory(
                                          customerImage,
                                          height: 72,
                                          width: 72,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  : CircleAvatar(
                                      backgroundColor:
                                          theme.colorScheme.secondary,
                                      radius: 36,
                                      child: Icon(
                                        Icons.person,
                                        color: theme.colorScheme.onSecondary,
                                        size: 36.0,
                                      ),
                                    ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      customer.name!,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: <Widget>[
                                        Icon(
                                          Icons.phone,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                          size: 16.0,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          customer.phone!,
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.8),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (customer.address != null &&
                                        customer.address!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: <Widget>[
                                            Icon(
                                              Icons.location_on,
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.6),
                                              size: 16.0,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                customer.address!,
                                                style: TextStyle(
                                                  color: theme
                                                      .colorScheme.onSurface
                                                      .withOpacity(0.8),
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Transaction Total and Actions
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: getCustomerTransactionsTotalWidget(
                                      widget.customerId),
                                ),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () async {
                                        await generatePdf();
                                      },
                                      icon: Icon(
                                        Icons.picture_as_pdf,
                                        size: 16.0,
                                        color: Colors.blue.shade600,
                                      ),
                                      label: Text(
                                        AppLocalizations.of(context)!
                                            .translate('exportText'),
                                        style: TextStyle(
                                          color: Colors.blue.shade600,
                                          fontSize: 14,
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
                    // Transactions List
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            if (!isDarkMode)
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, -2),
                              ),
                          ],
                        ),
                        child: getCustomerTransactions(widget.customerId),
                      ),
                    ),
                  ],
                ),
              ),
              if (_absorbing)
                AbsorbPointer(
                  absorbing: true,
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    constraints: const BoxConstraints.expand(),
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
        return Center(
          child: CircularProgressIndicator(color: theme.colorScheme.secondary),
        );
      },
    );
  }

  Widget getCustomerTransactionsTotalWidget(int cid) {
    return FutureBuilder<double>(
      future: transactionBloc.getCustomerTransactionsTotal(cid),
      builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
        if (snapshot.hasData) {
          double total = snapshot.data!;
          if (total == 0) return Container();

          final isPositive = !total.isNegative;
          final amountText = amountFormat(context, total.abs());

          return LayoutBuilder(
            builder: (context, constraints) {
              final fontSize = constraints.maxWidth > 200 ? 24.0 : 20.0;

              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${isPositive ? '+' : '-'} $amountText',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: isPositive
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                  ),
                ),
              );
            },
          );
        }
        return Container();
      },
    );
  }

  Widget getCustomerTransactions(int cid) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Transaction>>(
      future: transactionBloc.getTransactionsByCustomerId(cid),
      builder:
          (BuildContext context, AsyncSnapshot<List<Transaction>> snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No transactions made yet!",
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 80),
            physics: const BouncingScrollPhysics(),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, itemIndex) {
              final transaction = snapshot.data![itemIndex];
              final dateFormatted = formatDate(context, transaction.date!);
              final isPayment = transaction.ttype == 'payment';

              return Column(
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SingleTransaction(transaction.id!),
                        ),
                      );
                    },
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dateFormatted["day"]!,
                            style: TextStyle(
                              color: theme.colorScheme.secondary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dateFormatted['month']!,
                            style: TextStyle(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    title: Text(
                      transaction.comment!,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          amountFormat(context, transaction.amount!.abs()),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isPayment
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!
                              .translate(isPayment ? 'received' : 'given'),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.dividerColor,
                    indent: 16,
                    endIndent: 16,
                  ),
                ],
              );
            },
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading transactions",
              style: TextStyle(color: theme.colorScheme.error),
            ),
          );
        }

        return Center(
          child: LoadingAnimationWidget.fourRotatingDots(
            color: theme.colorScheme.secondary,
            size: 60,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
