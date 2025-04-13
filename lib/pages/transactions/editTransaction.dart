import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khata_connect/helpers/conversion.dart';
import 'package:khata_connect/helpers/appLocalizations.dart';
import '../../blocs/customerBloc.dart';
import '../../blocs/transactionBloc.dart';
import '../../models/customer.dart';
import '../../models/transaction.dart';
import 'singleTransaction.dart';

class EditTransaction extends StatefulWidget {
  final Transaction transaction;

  const EditTransaction(this.transaction, {Key? key}) : super(key: key);

  @override
  _EditTransactionState createState() => _EditTransactionState();
}

class _EditTransactionState extends State<EditTransaction> {
  final TransactionBloc _transactionBloc = TransactionBloc();
  final CustomerBloc _customerBloc = CustomerBloc();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  String _transType = "credit";
  String? _comment;
  int? _customerId;
  double? _amount;
  DateTime _date = DateTime.now();
  File? _attachment;
  Uint8List? _existingAttachment;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _transType = transaction.ttype!;
    _comment = transaction.comment;
    _amount = transaction.amount;
    _date = transaction.date!;
    _customerId = transaction.uid;

    if (transaction.attachment != null) {
      _existingAttachment = base64Decode(transaction.attachment!);
    }
  }

  @override
  void dispose() {
    _transactionBloc.dispose();
    _customerBloc.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2030, 8),
      builder: (BuildContext context, Widget? child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.secondary,
              onPrimary: theme.colorScheme.onSecondary,
              surface: theme.cardColor,
              onSurface: theme.colorScheme.onSurface,
            ),
            dialogBackgroundColor: theme.cardColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _date) {
      setState(() => _date = picked);
    }
  }

  Future<void> _getImageFrom(String from) async {
    try {
      final XFile? image = from == 'camera'
          ? await _picker.pickImage(source: ImageSource.camera)
          : await _picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final properties =
          await FlutterNativeImage.getImageProperties(image.path);
      final compressedImage = await FlutterNativeImage.compressImage(
        image.path,
        quality: 80,
        targetWidth: 800,
        targetHeight: (properties.height! * 800 / properties.width!).round(),
      );

      if (compressedImage.lengthSync() > 2000000) {
        _showErrorSnackbar(
            AppLocalizations.of(context)!.translate('imageSizeError'));
        return;
      }

      setState(() {
        _attachment = compressedImage;
        _existingAttachment = null;
      });
    } catch (e) {
      _showErrorSnackbar(AppLocalizations.of(context)!.translate('imageError'));
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<List<Customer>>(
      future: _customerBloc.getCustomers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                AppLocalizations.of(context)!
                    .translate('errorLoadingCustomers'),
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          );
        }

        final customers = snapshot.data ?? [];
        Customer? selectedCustomer;
        if (_customerId != null) {
          selectedCustomer = customers.firstWhere(
            (c) => c.id == _customerId,
            orElse: () => Customer(),
          );
        }

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            forceMaterialTransparency: true,
            title: Text(
              AppLocalizations.of(context)!.translate('editTransaction'),
              style: TextStyle(color: colorScheme.onSurface),
            ),
            iconTheme: IconThemeData(color: colorScheme.onSurface),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: colorScheme.primary,
            onPressed: _updateTransaction,
            icon: Icon(Icons.check, color: colorScheme.onPrimary),
            label: Text(
              AppLocalizations.of(context)!.translate('saveChanges'),
              style: TextStyle(color: colorScheme.onPrimary),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTransactionTypeChips(theme),
                  const SizedBox(height: 16),
                  _buildCustomerInfo(selectedCustomer, theme),
                  const SizedBox(height: 16),
                  _buildAmountField(theme),
                  const SizedBox(height: 16),
                  _buildCommentField(theme),
                  const SizedBox(height: 16),
                  _buildDatePicker(theme),
                  const SizedBox(height: 16),
                  _buildAttachmentSection(theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionTypeChips(ThemeData theme) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          selected: _transType == "credit",
          label: Text(AppLocalizations.of(context)!.translate('creditGiven')),
          selectedColor: theme.colorScheme.primary,
          onSelected: (selected) {
            if (selected) setState(() => _transType = "credit");
          },
        ),
        ChoiceChip(
          selected: _transType == "payment",
          label:
              Text(AppLocalizations.of(context)!.translate('paymentReceived')),
          selectedColor: theme.colorScheme.primary,
          onSelected: (selected) {
            if (selected) setState(() => _transType = "payment");
          },
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(Customer? customer, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Text(
            customer?.name ?? 'No customer selected',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(ThemeData theme) {
    return TextFormField(
      initialValue: _amount?.toString(),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!
            .translate('transactionAmountLabelMeta'),
        labelText:
            AppLocalizations.of(context)!.translate('transactionAmountLabel'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      style: TextStyle(color: theme.colorScheme.onSurface),
      validator: (input) {
        if (input == null || input.isEmpty) {
          return AppLocalizations.of(context)!
              .translate('transactionAmountError');
        }
        if (double.tryParse(input) == null || double.parse(input) <= 0) {
          return AppLocalizations.of(context)!
              .translate('transactionAmountErrorNumber');
        }
        return null;
      },
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onSaved: (input) => _amount = double.parse(input!),
    );
  }

  Widget _buildCommentField(ThemeData theme) {
    return TextFormField(
      initialValue: _comment,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!
            .translate('transactionCommentLabelMeta'),
        labelText:
            AppLocalizations.of(context)!.translate('transactionCommentLabel'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      style: TextStyle(color: theme.colorScheme.onSurface),
      maxLines: 3,
      onSaved: (input) => _comment = input,
    );
  }

  Widget _buildDatePicker(ThemeData theme) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: theme.colorScheme.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      onPressed: () => _selectDate(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Text(
            formatDate(context, _date)['full']!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('transactionImageLabel'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showUploadDialog,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline,
                width: 1,
              ),
            ),
            child: _attachment != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_attachment!, fit: BoxFit.cover),
                  )
                : _existingAttachment != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_existingAttachment!,
                            fit: BoxFit.cover),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!
                                  .translate('addImage'),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ),
      ],
    );
  }

  void _showUploadDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('addImage'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.camera_alt,
                        color: theme.colorScheme.secondary,
                      ),
                      label: Text(
                        AppLocalizations.of(context)!.translate('fromCamera'),
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _getImageFrom('camera');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(
                        Icons.photo_library,
                        color: theme.colorScheme.onPrimary,
                      ),
                      label: Text(
                        AppLocalizations.of(context)!.translate('fromGallery'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _getImageFrom('gallery');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateTransaction() async {
    final formState = _formKey.currentState;

    if (formState?.validate() ?? false) {
      formState?.save();

      if (_customerId == null) {
        _showErrorSnackbar(
            AppLocalizations.of(context)!.translate('customerSelectionLabel'));
        return;
      }

      if (_attachment != null && _attachment!.lengthSync() > 2000000) {
        _showErrorSnackbar(
            AppLocalizations.of(context)!.translate('imageSizeError'));
        return;
      }

      final transaction = widget.transaction
        ..ttype = _transType
        ..amount = _amount!
        ..comment = _comment
        ..date = _date
        ..uid = _customerId;

      if (_attachment != null) {
        transaction.attachment = base64Encode(_attachment!.readAsBytesSync());
      } else if (_existingAttachment == null) {
        transaction.attachment = null;
      }

      try {
        await _transactionBloc.updateTransaction(transaction);
        if (!mounted) return;

        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SingleTransaction(transaction.id!),
          ),
        );
      } catch (e) {
        _showErrorSnackbar(
            AppLocalizations.of(context)!.translate('transactionError'));
      }
    }
  }
}
