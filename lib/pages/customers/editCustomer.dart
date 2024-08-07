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

  String? _name, _phone, _address;
  File? _image;
  final picker = ImagePicker();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  Future<void> getImageFrom(String from) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: <Widget>[
              Icon(Icons.warning, color: Colors.redAccent),
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text('Image size exceeds limit.'),
              ),
            ],
          ),
        ),
      );
      return;
    }

    setState(() {
      _image = rawImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;

    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        //backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          title: const Text('Edit Customer',
              style: TextStyle(
                //color: Colors.black,
              )),
          //iconTheme: const IconThemeData(color: Colors.black),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            updateCustomer(customer);
          },
          icon: const Icon(Icons.check),
          label: const Text('Save Changes'),
          heroTag: "edit_customer",
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  customerImageWidget(customer.image),
                  SizedBox(height: 25,),
                  TextFormField(
                    initialValue: customer.name,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.person),
                      hintText: 'Enter customer name',
                      labelText: 'Name',
                    ),
                    validator: (input) {
                      if (input == null || input.isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                    onSaved: (input) => _name = input,
                  ),
                  TextFormField(
                    initialValue: customer.phone,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.call),
                      hintText: 'Enter customer phone',
                      labelText: 'Phone',
                    ),
                    validator: (input) {
                      if (input == null || input.isEmpty) {
                        return 'Phone number is required';
                      }
                      return null;
                    },
                    onSaved: (input) => _phone = input,
                  ),
                  TextFormField(
                    initialValue: customer.address,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.location_on),
                      hintText: 'Enter customer address',
                      labelText: 'Address',
                    ),
                    validator: null, // Add validation if needed
                    onSaved: (input) => _address = input,
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget customerImageWidget(String? image) {
    Uint8List? customerImage;
    if (image != null && image.isNotEmpty) {
      customerImage = base64Decode(image);
    }

    return Row(
      children: <Widget>[
        Center(
          child: _image == null
              ? image == null || image.isEmpty
                  ? Image.asset('assets/images/noimage_person.png', width: 60)
                  : Image.memory(customerImage!, width: 60)
              : Image.file(_image!, width: 60),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextButton(
            onPressed: showUploadDialog,
            child: const Text('Change Image'),
          ),
        ),
      ],
    );
  }

  void showUploadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Upload Image'),
          children: <Widget>[
            SimpleDialogOption(
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text('From Camera'),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                getImageFrom('camera');
              },
            ),
            SimpleDialogOption(
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text('From Gallery'),
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

  Future<void> updateCustomer(Customer customer) async {
    final formState = _formKey.currentState;

    if (formState != null && formState.validate()) {
      formState.save();

      if (_image != null && _image!.lengthSync() > 2000000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: <Widget>[
                Icon(Icons.warning, color: Colors.redAccent),
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text('Image size exceeds limit.'),
                ),
              ],
            ),
          ),
        );
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

      Navigator.of(context).pop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SingleCustomer(customer.id!),
        ),
      );
    }
  }
}
