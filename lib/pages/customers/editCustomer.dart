import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khata_connect/blocs/customerBloc.dart';
import 'package:khata_connect/pages/customers/singleCustomer.dart';

import '../../models/customer.dart';

class EditCustomer extends StatefulWidget {
  final Customer customer;

  const EditCustomer(this.customer, {Key? key}) : super(key: key);

  @override
  _EditCustomerState createState() => _EditCustomerState();
}

class _EditCustomerState extends State<EditCustomer> {
  final CustomerBloc customerBloc = CustomerBloc();
  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  String? _name, _phone, _address;
  File? _image;

  Future<void> getImageFrom(String from) async {
    try {
      final pickedFile = from == 'camera'
          ? await picker.pickImage(source: ImageSource.camera)
          : await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      final properties =
          await FlutterNativeImage.getImageProperties(pickedFile.path);
      final rawImage = await FlutterNativeImage.compressImage(
        pickedFile.path,
        quality: 80,
        targetWidth: 512,
        targetHeight: (properties.height! * 512 / properties.width!).round(),
      );

      if (rawImage.lengthSync() > 200000) {
        _showSnackBar('Image size exceeds limit');
        return;
      }

      setState(() => _image = rawImage);
    } catch (e) {
      _showSnackBar('Error selecting image: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final customer = widget.customer;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0,
        forceMaterialTransparency: true,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: Text(
          'Edit Customer',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => updateCustomer(customer),
        icon: Icon(Icons.check, color: theme.colorScheme.onSecondary),
        label: Text(
          'Save Changes',
          style: TextStyle(color: theme.colorScheme.onSecondary),
        ),
        backgroundColor: theme.colorScheme.secondary,
        heroTag: "edit_customer",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProfileImageSection(customer.image),
              const SizedBox(height: 24),
              _buildFormFields(customer, theme),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(String? image) {
    final theme = Theme.of(context);
    Uint8List? customerImage;

    if (image != null && image.isNotEmpty) {
      customerImage = base64Decode(image);
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: _image != null
                    ? Image.file(_image!, fit: BoxFit.cover)
                    : customerImage != null
                        ? Image.memory(customerImage, fit: BoxFit.cover)
                        : Image.asset(
                            'assets/images/noimage_person.png',
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
                    color: theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: theme.colorScheme.onSecondary,
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
            'Change Image',
            style: TextStyle(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(Customer customer, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
        boxShadow: [
          if (theme.brightness == Brightness.light)
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextFormField(
            initialValue: customer.name,
            decoration: InputDecoration(
              prefixIcon:
                  Icon(Icons.person, color: theme.colorScheme.secondary),
              hintText: 'Enter customer name',
              labelText: 'Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.cardColor,
            ),
            style: TextStyle(color: theme.colorScheme.onSurface),
            validator: (input) =>
                input?.isEmpty ?? true ? 'Name is required' : null,
            onSaved: (input) => _name = input,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: customer.phone,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.phone, color: theme.colorScheme.secondary),
              hintText: 'Enter customer phone',
              labelText: 'Phone',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.cardColor,
            ),
            style: TextStyle(color: theme.colorScheme.onSurface),
            validator: (input) =>
                input?.isEmpty ?? true ? 'Phone number is required' : null,
            onSaved: (input) => _phone = input,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: customer.address,
            decoration: InputDecoration(
              prefixIcon:
                  Icon(Icons.location_on, color: theme.colorScheme.secondary),
              hintText: 'Enter customer address',
              labelText: 'Address',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.cardColor,
            ),
            style: TextStyle(color: theme.colorScheme.onSurface),
            onSaved: (input) => _address = input,
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

  Future<void> updateCustomer(Customer customer) async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      if (_image != null && _image!.lengthSync() > 2000000) {
        _showSnackBar('Image size exceeds limit');
        return;
      }

      customer
        ..name = _name
        ..phone = _phone
        ..address = _address;

      if (_image != null) {
        customer.image = base64Encode(_image!.readAsBytesSync());
      }

      await customerBloc.updateCustomer(customer);

      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SingleCustomer(customer.id!),
        ),
      );
    }
  }
}
