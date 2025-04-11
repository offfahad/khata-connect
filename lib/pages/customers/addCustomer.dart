import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khata_connect/main.dart';
import 'package:khata_connect/pages/contacts/importContacts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../blocs/customerBloc.dart';
import '../../helpers/appLocalizations.dart';
import '../../models/customer.dart';

class AddCustomer extends StatefulWidget {
  const AddCustomer({super.key});

  @override
  State<AddCustomer> createState() => _AddCustomerState();
}

class _AddCustomerState extends State<AddCustomer> {
  final CustomerBloc customerBloc = CustomerBloc();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _name, _phone, _address;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final Customer _customer = Customer();

  Future<void> getImageFrom(String from) async {
    final XFile? image = from == 'camera'
        ? await _picker.pickImage(source: ImageSource.camera)
        : await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final ImageProperties properties =
        await FlutterNativeImage.getImageProperties(image.path);
    final File rawImage = await FlutterNativeImage.compressImage(
      image.path,
      quality: 80,
      targetWidth: 512,
      targetHeight: (properties.height! * 512 / properties.width!).round(),
    );

    if (rawImage.lengthSync() > 200000) {
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }

    setState(() {
      _image = rawImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        title: Text(
          AppLocalizations.of(context)!.translate('addCustomer'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: theme.colorScheme.secondary),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              label: Text(
                AppLocalizations.of(context)!.translate('importContacts'),
                style: const TextStyle(fontSize: 14),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ImportContacts()),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addCustomer,
        icon: const Icon(
          Icons.check,
          color: Colors.white,
        ),
        label: Text(
          AppLocalizations.of(context)!.translate('addCustomer'),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: theme.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 16),
                customerImageWidget(),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDarkMode
                        ? theme.colorScheme.surface.withOpacity(0.5)
                        : theme.colorScheme.surface,
                    boxShadow: isDarkMode
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person,
                              color: theme.colorScheme.secondary),
                          hintText: AppLocalizations.of(context)!
                              .translate('customerNameLabelMeta'),
                          labelText: AppLocalizations.of(context)!
                              .translate('customerNameLabel'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.cardColor,
                        ),
                        style:
                            TextStyle(color: theme.textTheme.bodyLarge?.color),
                        validator: (input) {
                          if (input == null || input.isEmpty) {
                            return AppLocalizations.of(context)!
                                .translate('customerNameError');
                          }
                          return null;
                        },
                        onSaved: (input) => _name = input,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.phone,
                              color: theme.colorScheme.secondary),
                          hintText: AppLocalizations.of(context)!
                              .translate('customerPhoneLabelMeta'),
                          labelText: AppLocalizations.of(context)!
                              .translate('customerPhoneLabel'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.cardColor,
                        ),
                        style:
                            TextStyle(color: theme.textTheme.bodyLarge?.color),
                        validator: (input) {
                          if (input == null || input.isEmpty) {
                            return AppLocalizations.of(context)!
                                .translate('customerPhoneError');
                          }
                          return null;
                        },
                        onSaved: (input) => _phone = input,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.location_on,
                              color: theme.colorScheme.secondary),
                          hintText: AppLocalizations.of(context)!
                              .translate('customerAddressLabelMeta'),
                          labelText: AppLocalizations.of(context)!
                              .translate('customerAddressLabel'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.cardColor,
                        ),
                        style:
                            TextStyle(color: theme.textTheme.bodyLarge?.color),
                        validator: null,
                        onSaved: (input) => _address = input,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget customerImageWidget() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.secondary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: _image == null
                      ? Image.asset(
                          'assets/images/noimage_person.png',
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          _image!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: showUploadDialog,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: showUploadDialog,
            child: Text(
              AppLocalizations.of(context)!.translate('customerImageLabel'),
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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
                'Update Image',
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

  void addCustomer() async {
    final formState = _formKey.currentState;

    if (formState?.validate() ?? false) {
      formState?.save();

      _customer
        ..name = _name
        ..phone = _phone
        ..address = _address
        ..image =
            _image != null ? base64Encode(_image!.readAsBytesSync()) : null;

      final prefs = await SharedPreferences.getInstance();
      _customer.businessId = prefs.getInt('selected_business') ?? 0;

      await customerBloc.addCustomer(_customer);

      Navigator.of(context).pop();
      setState(() {});
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage()),
      );
    }
  }
}
