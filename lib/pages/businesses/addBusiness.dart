import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khata_connect/pages/businesses/deleteBusiness.dart';

import '../../blocs/businessBloc.dart';
import '../../helpers/appLocalizations.dart';
import '../../providers/stateNotifier.dart';
import '../../main.dart';
import '../../models/business.dart';

class AddBusiness extends StatefulWidget {
  @override
  _AddBusinessState createState() => _AddBusinessState();
}

class _AddBusinessState extends State<AddBusiness> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  final BusinessBloc _businessBloc = BusinessBloc();

  String? _companyName;
  File? _logo;
  final ImagePicker _picker = ImagePicker();

  Business _business = Business();

  Future<void> getImageFrom(String from) async {
    XFile? image;
    if (from == 'camera') {
      image = await _picker.pickImage(source: ImageSource.camera);
    } else {
      image = await _picker.pickImage(source: ImageSource.gallery);
    }

    if (image == null) return;

    ImageProperties properties =
        await FlutterNativeImage.getImageProperties(image.path);
    File rawImage = await FlutterNativeImage.compressImage(image.path,
        quality: 80,
        targetWidth: 512,
        targetHeight: (properties.height! * 512 / properties.width!).round());

    if (rawImage.lengthSync() > 200000) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: <Widget>[
            Icon(Icons.warning, color: Colors.redAccent),
            Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                  AppLocalizations.of(context)!.translate('imageSizeError')),
            ),
          ],
        ),
      ));
      return;
    }

    setState(() {
      _logo = rawImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        //backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          title: Text(
            AppLocalizations.of(context)!.translate('addCompany'),
            style: TextStyle(
              //color: Colors.black,
            ),
          ),
          iconTheme: IconThemeData(
            //color: Colors.black,
          ),
          actions: <Widget>[
            TextButton.icon(
              label: Text(
                AppLocalizations.of(context)!.translate('deleteCompany'),
                style: TextStyle(fontSize: 12),
              ),
              icon: Icon(Icons.delete, size: 20.0, color: Colors.red),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeleteBusiness(),
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: addCompany,
          icon: Icon(Icons.check),
          label: Text(AppLocalizations.of(context)!.translate('addCompany')),
        ),
        body: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.only(bottom: 48),
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  customerImageWidget(),
                  TextFormField(
                    decoration: InputDecoration(
                      icon: Icon(Icons.business),
                      hintText: AppLocalizations.of(context)!
                          .translate('companyNameLabelMeta'),
                      labelText: AppLocalizations.of(context)!
                          .translate('companyNameLabel'),
                    ),
                    validator: (input) {
                      if (input == null || input.isEmpty) {
                        return AppLocalizations.of(context)!
                            .translate('companyNameLabelError');
                      }
                      return null;
                    },
                    onSaved: (input) => _companyName = input,
                  ),
                  Padding(padding: EdgeInsets.all(36)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget customerImageWidget() {
    return Row(
      children: <Widget>[
        Center(
          child: _logo == null
              ? Image.asset('assets/images/noimage_person.png', width: 60)
              : Image.file(_logo!, width: 60),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: TextButton(
            onPressed: showUploadDialog,
            child: Text(
                AppLocalizations.of(context)!.translate('companyImageLabel')),
          ),
        ),
      ],
    );
  }

  void showUploadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              AppLocalizations.of(context)!.translate('companyImageLabel')),
          actions: <Widget>[
            TextButton(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(AppLocalizations.of(context)!
                    .translate('uploadFromCamera')),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                getImageFrom('camera');
              },
            ),
            TextButton(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(AppLocalizations.of(context)!
                    .translate('uploadFromGallery')),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                getImageFrom('gallery');
              },
            ),
          ],
        );
      },
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
              Icon(Icons.warning, color: Colors.redAccent),
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                    AppLocalizations.of(context)!.translate('imageSizeError')),
              ),
            ],
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
