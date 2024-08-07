import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

import '../../blocs/businessBloc.dart';
import '../../database/businessRepo.dart';
import '../../helpers/appLocalizations.dart';
import '../../models/business.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart' as pdf;

class BusinessInformation extends StatefulWidget {
  @override
  _BusinessInformationState createState() => _BusinessInformationState();
}

class _BusinessInformationState extends State<BusinessInformation> {
  final BusinessBloc businessBloc = BusinessBloc();
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Business? _businessInfo = Business();
  Future<Business>? _businessFuture;
  final BusinessRepository _businessRepository = BusinessRepository();
  final ImagePicker _picker = ImagePicker();

  bool _savingCompany = false;

  @override
  void initState() {
    super.initState();
    initBusinessCard();
  }

  Future<void> downloadPdf() async {
    await buildPDF();
    final dir = await getExternalStorageDirectory();
    final file = File('${dir?.path}/business_card.pdf');
    OpenFile.open(file.path);
  }

  Future<void> initBusinessCard() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    int? selectedBusinessId = prefs.getInt('selected_business') ?? 0;

    setState(() {
      _businessFuture = _businessRepository.getBusiness(selectedBusinessId);
    });

    Business? businessz = await businessBloc.getBusiness(selectedBusinessId);

    if (businessz != null) {
      setState(() {
        _businessInfo = businessz;
      });
    }
  }

  Future<void> buildPDF() async {
    if (!mounted) return;
    await businessCardMaker();
  }

  Future<void> businessCardMaker() async {
    final doc = pw.Document();

    // Load image bytes from assets
    final backgroundImageBytes =
        await rootBundle.load('assets/images/cv_template.png');
    final phoneImageBytes = await rootBundle.load('assets/images/cv/phone.png');
    final emailImageBytes = await rootBundle.load('assets/images/cv/email.png');
    final locationImageBytes =
        await rootBundle.load('assets/images/cv/location.png');
    final websiteImageBytes =
        await rootBundle.load('assets/images/cv/website.png');

    // Convert bytes to pw.ImageProvider
    final backgroundImage =
        pw.MemoryImage(backgroundImageBytes.buffer.asUint8List());
    final phoneImage = pw.MemoryImage(phoneImageBytes.buffer.asUint8List());
    final emailImage = pw.MemoryImage(emailImageBytes.buffer.asUint8List());
    final locationImage =
        pw.MemoryImage(locationImageBytes.buffer.asUint8List());
    final websiteImage = pw.MemoryImage(websiteImageBytes.buffer.asUint8List());

    // Optionally handle the business logo if available
    pw.MemoryImage? businessLogo;
    if (_businessInfo!.logo != null && _businessInfo!.logo!.isNotEmpty) {
      final logoBytes = base64Decode(_businessInfo!.logo!);
      businessLogo = pw.MemoryImage(logoBytes);
    }

    doc.addPage(
      pw.Page(
        pageFormat: const pdf.PdfPageFormat(1200, 680),
        build: (pw.Context context) => pw.Container(
          child: pw.Stack(
            children: [
              pw.Container(
                alignment: pw.Alignment.center,
                height: 700,
                child: pw.Image(backgroundImage, height: 700),
              ),
              pw.Container(
                height: 700,
                padding: const pw.EdgeInsets.fromLTRB(0, 140, 80, 0),
                alignment: pw.Alignment.center,
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 700,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          businessLogo != null
                              ? pw.Image(businessLogo, height: 80)
                              : pw.SizedBox(height: 80),
                          pw.SizedBox(height: 24),
                          pw.Text(
                            _businessInfo!.companyName ?? "COMPANY NAME",
                            style: const pw.TextStyle(
                              fontSize: 36,
                              color: pdf.PdfColor.fromInt(0xfff1f1f1),
                            ),
                          ),
                          pw.SizedBox(height: 32),
                          pw.RichText(
                            text: pw.TextSpan(
                              text: _businessInfo!.name != null
                                  ? _businessInfo!.name!.split(" ")[0]
                                  : "",
                              style: pw.TextStyle(
                                fontSize: 54,
                                color: const pdf.PdfColor.fromInt(0xffffffff),
                                fontWeight: pw.FontWeight.bold,
                              ),
                              children: <pw.TextSpan>[
                                pw.TextSpan(
                                  text: _businessInfo!.name != null
                                      ? " ${_businessInfo!.name!.split(" ").length > 1 ? _businessInfo!.name!.split(" ")[1] : ""}"
                                      : "",
                                  style: pw.TextStyle(
                                    fontSize: 54,
                                    color:
                                        const pdf.PdfColor.fromInt(0xffffffff),
                                    fontWeight: pw.FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 24),
                          pw.Text(
                            _businessInfo!.role ?? "",
                            style: const pw.TextStyle(
                              fontSize: 36,
                              color: pdf.PdfColor.fromInt(0xfff1f1f1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Spacer(),
                    pw.Container(
                      padding: const pw.EdgeInsets.fromLTRB(0, 80, 0, 0),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _businessInfo!.phone != null &&
                                  _businessInfo!.phone!.isNotEmpty
                              ? pw.Row(
                                  children: [
                                    pw.Image(phoneImage, height: 30),
                                    pw.SizedBox(width: 20),
                                    pw.Text(
                                      _businessInfo!.phone!,
                                      style: const pw.TextStyle(
                                        fontSize: 32,
                                        color: pdf.PdfColor.fromInt(0xfff1f1f1),
                                      ),
                                    ),
                                  ],
                                )
                              : pw.Container(),
                          pw.SizedBox(height: 36),
                          _businessInfo!.address != null &&
                                  _businessInfo!.address!.isNotEmpty
                              ? pw.Row(
                                  children: [
                                    pw.Image(locationImage, height: 30),
                                    pw.SizedBox(width: 20),
                                    pw.Text(
                                      _businessInfo!.address!,
                                      style: const pw.TextStyle(
                                        fontSize: 32,
                                        color: pdf.PdfColor.fromInt(0xfff1f1f1),
                                      ),
                                    ),
                                  ],
                                )
                              : pw.Container(),
                          pw.SizedBox(height: 36),
                          _businessInfo!.email != null &&
                                  _businessInfo!.email!.isNotEmpty
                              ? pw.Row(
                                  children: [
                                    pw.Image(emailImage, height: 30),
                                    pw.SizedBox(width: 20),
                                    pw.Text(
                                      _businessInfo!.email!,
                                      style: const pw.TextStyle(
                                        fontSize: 32,
                                        color: pdf.PdfColor.fromInt(0xfff1f1f1),
                                      ),
                                    ),
                                  ],
                                )
                              : pw.Container(),
                          pw.SizedBox(height: 36),
                          _businessInfo!.website != null &&
                                  _businessInfo!.website!.isNotEmpty
                              ? pw.Row(
                                  children: [
                                    pw.Image(websiteImage, height: 30),
                                    pw.SizedBox(width: 20),
                                    pw.Text(
                                      _businessInfo!.website!,
                                      style: const pw.TextStyle(
                                        fontSize: 32,
                                        color: pdf.PdfColor.fromInt(0xfff1f1f1),
                                      ),
                                    ),
                                  ],
                                )
                              : pw.Container(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final pdfBytes = await doc.save();
    final dir = await getExternalStorageDirectory();
    final file = File('${dir?.path}/business_card.pdf');
    file.writeAsBytesSync(pdfBytes);
  }

  Future<void> updateBusinessInformation() async {
    if (!mounted) return;

    setState(() {
      _savingCompany = true;
    });

    final formState = _formKey.currentState;
    if (formState?.validate() ?? false) {
      formState?.save(); // Ensure the form data is saved

      try {
        final getBusinessInfo =
            await businessBloc.getBusiness(_businessInfo!.id ?? 0);
        if (getBusinessInfo == null) {
          await businessBloc.addBusiness(_businessInfo!);
          print('Business added successfully');
        } else {
          await businessBloc.updateBusiness(_businessInfo!);
          print('Business updated successfully');
        }
        // Fetch the updated business information
        final updatedBusiness =
            await businessBloc.getBusiness(_businessInfo!.id ?? 0);

        setState(() {
          _businessInfo = updatedBusiness!;
        });

        Navigator.pop(
            context, _businessInfo); // Pass the updated business info back

        // Show a Snackbar for 5 seconds with a message to restart the app
        final snackBar = SnackBar(
          content: Text(
              'Business information updated successfully. Restart your app to see the changes.'),
          duration: Duration(seconds: 5),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } catch (e) {
        print('Error updating business: $e');
        _showErrorDialog('Failed to update business. Please try again later.');
      }
    } else {
      print('Form validation failed');
      _showErrorDialog('Form validation failed');
    }

    if (mounted) {
      setState(() {
        _savingCompany = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> getImageFrom(String from) async {
    if (!mounted) return;

    final XFile? image = await _picker.pickImage(
        source: from == 'camera' ? ImageSource.camera : ImageSource.gallery);

    if (image != null) {
      File imageFile = File(image.path);

      final result = await FlutterNativeImage.compressImage(
        imageFile.path,
        quality: 100,
        targetWidth: 200,
        targetHeight: 200,
      );

      final imageBase64 = base64Encode(result.readAsBytesSync());

      setState(() {
        _businessInfo!.logo = imageBase64;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.translate('businessInfo')),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red,),
              onPressed: downloadPdf,
            ),
          ],
        ),
        body: FutureBuilder<Business?>(
          future: _businessFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: LoadingAnimationWidget.fourRotatingDots(
                    color: Theme.of(context).colorScheme.secondary, size: 60),
              );
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('No data found.'));
            }

            _businessInfo = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: _businessInfo!.companyName,
                      decoration:
                          const InputDecoration(labelText: 'Company Name'),
                      onSaved: (value) => _businessInfo!.companyName = value,
                    ),
                    TextFormField(
                      initialValue: _businessInfo!.name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      onSaved: (value) => _businessInfo!.name = value,
                    ),
                    TextFormField(
                      initialValue: _businessInfo!.role,
                      decoration: const InputDecoration(labelText: 'Role'),
                      onSaved: (value) => _businessInfo!.role = value,
                    ),
                    TextFormField(
                      initialValue: _businessInfo!.phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      onSaved: (value) => _businessInfo!.phone = value,
                    ),
                    TextFormField(
                      initialValue: _businessInfo!.address,
                      decoration: const InputDecoration(labelText: 'Address'),
                      onSaved: (value) => _businessInfo!.address = value,
                    ),
                    TextFormField(
                      initialValue: _businessInfo!.email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      onSaved: (value) => _businessInfo!.email = value,
                    ),
                    TextFormField(
                      initialValue: _businessInfo!.website,
                      decoration: const InputDecoration(labelText: 'Website'),
                      onSaved: (value) => _businessInfo!.website = value,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, // Full width button
                      height: 50, // Increase height as needed
                      child: ElevatedButton(
                        onPressed: () => getImageFrom('gallery'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                8.0), // Adjust border radius for rectangular shape
                          ),
                        ),
                        child: const Text('Select Logo'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _savingCompany
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity, // Full width button
                            height: 50, // Increase height as needed
                            child: ElevatedButton(
                              onPressed: updateBusinessInformation,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8.0), // Adjust border radius for rectangular shape
                                ),
                              ),
                              child: Text(AppLocalizations.of(context)!
                                  .translate('Save')),
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
