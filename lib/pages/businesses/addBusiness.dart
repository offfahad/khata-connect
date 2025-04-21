import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khata_connect/pages/businesses/deleteBusiness.dart';

import '../../blocs/businessBloc.dart';
import '../../helpers/appLocalizations.dart';
import '../../providers/stateNotifier.dart';
import '../../main.dart';
import '../../models/business.dart';

class AddBusiness extends StatefulWidget {
  const AddBusiness({super.key});

  @override
  State<AddBusiness> createState() => _AddBusinessState();
}

class _AddBusinessState extends State<AddBusiness> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  final BusinessBloc _businessBloc = BusinessBloc();

  String? _companyName;
  File? _logo;
  final ImagePicker _picker = ImagePicker();

  final Business _business = Business();

  Future<void> getImageFrom(String from) async {
    XFile? image;
    if (from == 'camera') {
      image = await _picker.pickImage(source: ImageSource.camera);
    } else {
      image = await _picker.pickImage(source: ImageSource.gallery);
    }

    if (image == null) return;

    final File originalFile = File(image.path);

    final List<int>? compressedBytes =
        await FlutterImageCompress.compressWithFile(
      originalFile.absolute.path,
      quality: 80,
      minWidth: 512,
      keepExif: true,
    );

    if (compressedBytes == null || compressedBytes.length > 200000) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: <Widget>[
            const Icon(Icons.warning, color: Colors.redAccent),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                AppLocalizations.of(context)!.translate('imageSizeError'),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ));
      return;
    }

    final File compressedImage = File(
      '${originalFile.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await compressedImage.writeAsBytes(compressedBytes);

    setState(() {
      _logo = compressedImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0,
        forceMaterialTransparency: true,
        title: Text(
          AppLocalizations.of(context)!.translate('addCompany'),
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
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.redAccent),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              label: Text(
                AppLocalizations.of(context)!.translate('deleteCompany'),
                style: const TextStyle(fontSize: 14),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeleteBusiness(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addCompany,
        icon: const Icon(Icons.check),
        label: Text(AppLocalizations.of(context)!.translate('addCompany')),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(bottom: 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 16),
                companyLogoWidget(),
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.business,
                              color: theme.colorScheme.secondary),
                          hintText: AppLocalizations.of(context)!
                              .translate('companyNameLabelMeta'),
                          labelText: AppLocalizations.of(context)!
                              .translate('companyNameLabel'),
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
                                .translate('companyNameLabelError');
                          }
                          return null;
                        },
                        onSaved: (input) => _companyName = input,
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

  Widget companyLogoWidget() {
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
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _logo == null
                      ? Image.asset(
                          'assets/images/noimage_person.png',
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          _logo!,
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
                    child: const Icon(Icons.camera_alt,
                        size: 20, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: showUploadDialog,
            child: Text(
              AppLocalizations.of(context)!.translate('companyImageLabel'),
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

  void addCompany() async {
    final formState = _formKey.currentState;

    if (formState != null && formState.validate()) {
      formState.save();

      // Check image and its size (2MB)
      if (_logo != null && _logo!.lengthSync() > 2000000) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: <Widget>[
              const Icon(Icons.warning, color: Colors.redAccent),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                    AppLocalizations.of(context)!.translate('imageSizeError')),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ));
        return;
      }

      _business.companyName = _companyName ?? '';
      _business.name = '';
      _business.phone = '';
      _business.email = '';
      _business.address = '';
      _business.logo = '';
      _business.website = '';
      _business.role = '';

      if (_logo != null) {
        String base64Image = base64Encode(await _logo!.readAsBytes());
        _business.logo = base64Image;
      }

      List<Business> businessesList = await _businessBloc.getBusinesss();
      _business.id = businessesList.length;
      if (_business.id! > 5) return;
      await _businessBloc.addBusiness(_business);
      changeSelectedBusiness(context, _business.id!);
      Navigator.of(context).pop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyHomePage(),
        ),
      );
    }
  }
}
