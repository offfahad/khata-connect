import 'dart:convert';
import 'dart:io';

import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khata_connect/blocs/customerBloc.dart';
import 'package:khata_connect/blocs/transactionBloc.dart';
import 'package:khata_connect/pages/customers/singleCustomer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khata_connect/models/customer.dart';
import 'package:khata_connect/models/transaction.dart';
import 'package:khata_connect/helpers/appLocalizations.dart';
import 'package:khata_connect/helpers/conversion.dart';

class AddTransaction extends StatefulWidget {
  final Customer? customer;
  final String transType;

  const AddTransaction({super.key, this.customer, required this.transType});

  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  String _transType = "credit";
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
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _transType = widget.transType;
    if (widget.customer != null) {
      _customerId = widget.customer!.id;
      _customerName = widget.customer!.name;
    }
    _comment = _transType == "credit" ? "Credit given" : "Payment received";
  }

  @override
  void dispose() {
    _amountController.dispose();
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
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> getImageFrom(String from) async {
    try {
      final XFile? image = from == 'camera'
          ? await picker.pickImage(source: ImageSource.camera)
          : await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final File originalFile = File(image.path);

      // Compress image with target width and quality
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        originalFile.absolute.path,
        quality: 80,
        minWidth: 800, // No height required; aspect ratio is preserved
        keepExif: true,
      );

      if (compressedBytes == null || compressedBytes.length > 2000000) {
        _showErrorSnackbar(
          AppLocalizations.of(context)!.translate('imageSizeError'),
        );
        return;
      }

      // Save compressed image to a new file
      final File compressedImage = File(
        '${originalFile.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await compressedImage.writeAsBytes(compressedBytes);

      setState(() {
        _attachment = compressedImage;
      });
    } catch (e) {
      _showErrorSnackbar(
        AppLocalizations.of(context)!.translate('imageError'),
      );
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
    final isDarkMode = theme.brightness == Brightness.dark;

    return FutureBuilder<List<Customer>>(
      future: customerBloc.getCustomers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                AppLocalizations.of(context)!
                    .translate('errorLoadingCustomers'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          );
        }

        final List<Customer> customers = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            forceMaterialTransparency: true,
            title: Text(
              AppLocalizations.of(context)!.translate('addTransaction'),
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: theme.primaryColor,
            onPressed: addTransaction,
            icon: Icon(Icons.check, color: theme.colorScheme.onPrimary),
            label: Text(
              AppLocalizations.of(context)!.translate('addTransaction'),
              style: TextStyle(color: theme.colorScheme.onPrimary),
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
                  widget.customer != null
                      ? _buildCustomerInfo(theme)
                      : _buildCustomerAutocomplete(customers, theme),
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
          selectedColor: theme.primaryColor,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _transType = "credit";
                _comment = "Credit Given";
              });
            }
          },
        ),
        ChoiceChip(
          selected: _transType == "payment",
          label:
              Text(AppLocalizations.of(context)!.translate('paymentReceived')),
          selectedColor: theme.primaryColor,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _transType = "payment";
                _comment = "Payment Received";
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(ThemeData theme) {
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
            _customerName!,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerAutocomplete(List<Customer> customers, ThemeData theme) {
    return AutoCompleteTextField<Customer>(
      key: _customerSuggestionKey,
      clearOnSubmit: false,
      suggestions: customers,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.person, color: theme.colorScheme.onSurface),
        hintText:
            AppLocalizations.of(context)!.translate('customerNameLabelMeta'),
        labelText: AppLocalizations.of(context)!.translate('customerNameLabel'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      style: TextStyle(color: theme.colorScheme.onSurface),
      itemFilter: (item, query) {
        _customerName = query;
        _customerId = null;
        return item.name!.toLowerCase().contains(query.toLowerCase());
      },
      itemSorter: (a, b) => a.name!.compareTo(b.name!),
      itemSubmitted: (item) {
        setState(() {
          _customerName = item.name;
          _customerId = item.id;
        });
      },
      itemBuilder: (context, item) => ListTile(
        title: Text(item.name!,
            style: TextStyle(color: theme.colorScheme.onSurface)),
      ),
    );
  }

  Widget _buildAmountField(ThemeData theme) {
    return TextFormField(
      controller: _amountController,
      autofocus: true,
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
          onTap: showUploadDialog,
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
            child: _attachment == null
                ? Center(
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
                          AppLocalizations.of(context)!.translate('addImage'),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_attachment!, fit: BoxFit.cover),
                  ),
          ),
        ),
      ],
    );
  }

  void showUploadDialog() {
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
                        'From Camera',
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
                        getImageFrom('camera');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                      ),
                      label: const Text('From Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        getImageFrom('gallery');
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

  Future<void> addTransaction() async {
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
        if (!mounted) return;

        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SingleCustomer(_customerId!),
          ),
        );
      } catch (e) {
        _showErrorSnackbar(
            AppLocalizations.of(context)!.translate('transactionError'));
      }
    }
  }
}
