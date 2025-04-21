import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart' as pdf;

import '../../blocs/businessBloc.dart';
import '../../database/businessRepo.dart';
import '../../helpers/appLocalizations.dart';
import '../../models/business.dart';

class BusinessInformation extends StatefulWidget {
  @override
  _BusinessInformationState createState() => _BusinessInformationState();
}

class _BusinessInformationState extends State<BusinessInformation> {
  final BusinessBloc _businessBloc = BusinessBloc();
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Business? _businessInfo = Business();
  Future<Business>? _businessFuture;
  final BusinessRepository _businessRepository = BusinessRepository();
  final ImagePicker _picker = ImagePicker();

  bool _savingCompany = false;
  bool _generatingPdf = false;

  @override
  void initState() {
    super.initState();
    initBusinessCard();
  }

  @override
  void dispose() {
    _businessBloc.dispose();
    super.dispose();
  }

  Future<void> downloadPdf() async {
    if (!mounted) return;

    setState(() {
      _generatingPdf = true;
    });

    try {
      final file = await buildPDF();
      if (file != null) {
        await OpenFile.open(file.path);
      }
    } catch (e) {
      _showErrorDialog('Failed to generate PDF: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _generatingPdf = false;
        });
      }
    }
  }

  Future<void> initBusinessCard() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    int? selectedBusinessId = prefs.getInt('selected_business') ?? 0;

    setState(() {
      _businessFuture = _businessRepository.getBusiness(selectedBusinessId);
    });

    Business? businessz = await _businessBloc.getBusiness(selectedBusinessId);

    if (businessz != null) {
      setState(() {
        _businessInfo = businessz;
      });
    }
  }

  Future<File?> buildPDF() async {
    final doc = pw.Document();

    try {
      // Load a font that supports Unicode
      final fontData =
          await rootBundle.load('assets/fonts/Quicksand/Quicksand-Regular.ttf');
      final font = pw.Font.ttf(fontData);

      // Create PDF
      doc.addPage(
        pw.Page(
          pageFormat: const pdf.PdfPageFormat(1200, 680),
          build: (pw.Context context) => pw.Container(
            decoration: pw.BoxDecoration(
              color: pdf.PdfColors.white,
              border: pw.Border.all(color: pdf.PdfColors.black, width: 1),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (_businessInfo?.logo != null &&
                      _businessInfo!.logo!.isNotEmpty)
                    pw.Center(
                      child: pw.Image(
                        pw.MemoryImage(base64Decode(_businessInfo!.logo!)),
                        height: 100,
                      ),
                    ),
                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.Text(
                      _businessInfo?.companyName ?? 'COMPANY NAME',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 36,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    _businessInfo?.name ?? '',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 24,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    _businessInfo?.role ?? '',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 20,
                      color: pdf.PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 30),
                  if (_businessInfo?.phone?.isNotEmpty ?? false)
                    _buildPdfContactRow('Phone:', _businessInfo!.phone!, font),
                  if (_businessInfo?.email?.isNotEmpty ?? false)
                    _buildPdfContactRow('Email:', _businessInfo!.email!, font),
                  if (_businessInfo?.address?.isNotEmpty ?? false)
                    _buildPdfContactRow(
                        'Address:', _businessInfo!.address!, font),
                  if (_businessInfo?.website?.isNotEmpty ?? false)
                    _buildPdfContactRow(
                        'Website:', _businessInfo!.website!, font),
                ],
              ),
            ),
          ),
        ),
      );

      // Save to temporary directory
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/business_card.pdf');
      await file.writeAsBytes(await doc.save());
      return file;
    } catch (e) {
      print('PDF generation error: $e');
      return null;
    }
  }

  pw.Widget _buildPdfContactRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        children: [
          pw.Text(
            '$label ',
            style: pw.TextStyle(
              font: font,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: font,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> updateBusinessInformation() async {
    if (!mounted) return;

    setState(() {
      _savingCompany = true;
    });

    final formState = _formKey.currentState;
    if (formState?.validate() ?? false) {
      formState?.save();

      try {
        final getBusinessInfo =
            await _businessBloc.getBusiness(_businessInfo!.id ?? 0);
        if (getBusinessInfo == null) {
          await _businessBloc.addBusiness(_businessInfo!);
        } else {
          await _businessBloc.updateBusiness(_businessInfo!);
        }

        final updatedBusiness =
            await _businessBloc.getBusiness(_businessInfo!.id ?? 0);
        setState(() {
          _businessInfo = updatedBusiness;
        });

        Navigator.pop(context, _businessInfo);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Business information updated successfully.'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        _showErrorDialog('Failed to update business: ${e.toString()}');
      }
    } else {
      _showErrorDialog('Please fill all required fields');
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
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> getImageFrom(String from) async {
    if (!mounted) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: from == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final File originalFile = File(image.path);

        final List<int>? compressedBytes =
            await FlutterImageCompress.compressWithFile(
          originalFile.absolute.path,
          quality: 80,
          minWidth: 800,
          keepExif: true,
        );

        if (compressedBytes == null) {
          _showErrorDialog('Image compression failed.');
          return;
        }

        final imageBase64 = base64Encode(compressedBytes);

        setState(() {
          _businessInfo!.logo = imageBase64;
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to select image: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0,
        forceMaterialTransparency: true,
        title: Text(
          AppLocalizations.of(context)!.translate('businessInfo'),
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: IconButton(
              icon: _generatingPdf
                  ? LoadingAnimationWidget.threeRotatingDots(
                      color: colorScheme.primary,
                      size: 24,
                    )
                  : Icon(
                      Icons.picture_as_pdf,
                      color: colorScheme.error,
                    ),
              onPressed: _generatingPdf ? null : downloadPdf,
            ),
          ),
        ],
      ),
      body: FutureBuilder<Business?>(
        future: _businessFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.fourRotatingDots(
                color: colorScheme.primary,
                size: 60,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Text(
                'No data found.',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            );
          }

          _businessInfo = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_businessInfo?.logo != null &&
                      _businessInfo!.logo!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: colorScheme.surfaceVariant,
                          backgroundImage: MemoryImage(
                            base64Decode(_businessInfo!.logo!),
                          ),
                        ),
                      ),
                    ),
                  _buildTextFormField(
                    context,
                    initialValue: _businessInfo!.companyName,
                    label: 'Company Name',
                    onSaved: (value) => _businessInfo!.companyName = value,
                  ),
                  _buildTextFormField(
                    context,
                    initialValue: _businessInfo!.name,
                    label: 'Name',
                    onSaved: (value) => _businessInfo!.name = value,
                  ),
                  _buildTextFormField(
                    context,
                    initialValue: _businessInfo!.role,
                    label: 'Role',
                    onSaved: (value) => _businessInfo!.role = value,
                  ),
                  _buildTextFormField(
                    context,
                    initialValue: _businessInfo!.phone,
                    label: 'Phone',
                    keyboardType: TextInputType.phone,
                    onSaved: (value) => _businessInfo!.phone = value,
                  ),
                  _buildTextFormField(
                    context,
                    initialValue: _businessInfo!.address,
                    label: 'Address',
                    onSaved: (value) => _businessInfo!.address = value,
                  ),
                  _buildTextFormField(
                    context,
                    initialValue: _businessInfo!.email,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (value) => _businessInfo!.email = value,
                  ),
                  _buildTextFormField(
                    context,
                    initialValue: _businessInfo!.website,
                    label: 'Website',
                    keyboardType: TextInputType.url,
                    onSaved: (value) => _businessInfo!.website = value,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Select Logo'),
                      onPressed: () => getImageFrom('gallery'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _savingCompany ? null : updateBusinessInformation,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _savingCompany
                          ? const CircularProgressIndicator()
                          : Text(
                              AppLocalizations.of(context)!.translate('Save'),
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextFormField(
    BuildContext context, {
    required String? initialValue,
    required String label,
    required void Function(String?) onSaved,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
        ),
        keyboardType: keyboardType,
        style: TextStyle(color: colorScheme.onSurface),
        onSaved: onSaved,
      ),
    );
  }
}
