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

  const SingleTransaction(this.transactionId, {super.key});

  @override
  State<SingleTransaction> createState() => _SingleTransactionState();
}

class _SingleTransactionState extends State<SingleTransaction> {
  final TransactionBloc _transactionBloc = TransactionBloc();
  final CustomerBloc _customerBloc = CustomerBloc();

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
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(
                AppLocalizations.of(context)!.translate('deleteText'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                ),
              ),
              onPressed: () {
                _transactionBloc.deleteTransactionById(transaction.id!);
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return FutureBuilder<Transaction>(
      future: _transactionBloc.getTransaction(widget.transactionId),
      builder: (BuildContext context, AsyncSnapshot<Transaction> snapshot) {
        if (snapshot.hasData) {
          final transaction = snapshot.data!;
          Uint8List? transactionAttachment;

          if (transaction.attachment != null) {
            transactionAttachment =
                const Base64Decoder().convert(transaction.attachment!);
          }

          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              forceMaterialTransparency: true,
              centerTitle: false,
              title: Text(
                AppLocalizations.of(context)!.translate('transactionDetails'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 24),
                  color: colorScheme.primary,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTransaction(transaction),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 24),
                  color: colorScheme.error,
                  onPressed: () => _showDeleteDialog(transaction),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Customer and date section
                  Center(child: _buildCustomerInfo(transaction)),
                  const SizedBox(height: 24),

                  // Transaction type and amount
                  _buildTransactionTypeAndAmount(context, transaction),
                  const SizedBox(height: 24),

                  // Divider
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 24),

                  // // Comment section
                  // if (transaction.comment != null &&
                  //     transaction.comment!.isNotEmpty)
                  _buildCommentSection(transaction, colorScheme),
                  if (transaction.comment != null &&
                      transaction.comment!.isNotEmpty)
                    const SizedBox(height: 24),

                  // Attachment section
                  if (transactionAttachment != null)
                    _buildAttachmentSection(transactionAttachment, context),
                ],
              ),
            ),
          );
        }

        return Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        );
      },
    );
  }

  Widget _buildCustomerInfo(Transaction transaction) {
    return FutureBuilder<Customer>(
      future: _customerBloc.getCustomer(transaction.uid!),
      builder: (BuildContext context, AsyncSnapshot<Customer> snapshot) {
        if (snapshot.hasData) {
          final customer = snapshot.data!;
          final colorScheme = Theme.of(context).colorScheme;

          return Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  size: 24,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${transaction.date!.day}/${transaction.date!.month}/${transaction.date!.year}",
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTransactionTypeAndAmount(
      BuildContext context, Transaction transaction) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCredit = transaction.ttype == 'credit';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isCredit
                      ? colorScheme.errorContainer
                      : colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 20,
                  color: isCredit
                      ? colorScheme.onErrorContainer
                      : colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.translate(
                  isCredit ? 'creditGiven' : 'paymentReceived',
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(
            width: 20,
          ),
          Flexible(
            child: Text(
              amountFormat(context, transaction.amount!.abs()),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isCredit ? colorScheme.error : colorScheme.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection(
      Transaction transaction, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            transaction.comment!,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentSection(
      Uint8List transactionAttachment, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            transactionAttachment,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _transactionBloc.dispose();
    _customerBloc.dispose();
    super.dispose();
  }
}
