import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:khata_connect/firebase_options.dart';
import 'package:khata_connect/helpers/firebaseBackup.dart';
import 'package:khata_connect/pages/auth/signin.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../helpers/appLocalizations.dart';
import '../../helpers/constants.dart';

class Backup extends StatefulWidget {
  @override
  _BackupState createState() => _BackupState();
}

class _BackupState extends State<Backup> {
  bool _absorbing = true;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  

  @override
  void initState() {
    super.initState();
    _goToLoginScreen();
  }

  Future<void> _initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, // Use the generated options
    );
  }

  void _goToLoginScreen() async {
    await _initFirebase();
    final FirebaseAuth _auth = FirebaseAuth.instance;
    if (_auth.currentUser == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) {
            return SignIn();
          },
        ),
      );
    }

    setState(() {
      _absorbing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.translate('backupInfo')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Image(
                    image: AssetImage("assets/images/data-copy.jpg"),
                    width: 300,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.restore),
                    onPressed: () async {
                      setState(() {
                        _absorbing = true;
                      });
                      bool restored = await FirebaseBackup().restoreAllData();
                      
                      if (restored) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.translate('backupRestored'),
                          ),
                        ));
                      }
                      setState(() {
                        _absorbing = false;
                      });
                      setState(() {
                        
                      });
                    },
                    label: Text(AppLocalizations.of(context)!.translate('restoreNow')),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50), // Make buttons expand
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: xDarkBlue,
                      minimumSize: const Size.fromHeight(50), // Make buttons expand
                    ),
                    onPressed: () async {
                      setState(() {
                        _absorbing = true;
                      });

                      bool res = await FirebaseBackup().backupAllData();
                      if (res) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.translate('backupDone'),
                          ),
                        ));
                      }

                      setState(() {
                        _absorbing = false;
                      });
                      setState(() {
                        
                      });
                    },
                    label: Text(
                      AppLocalizations.of(context)!.translate('backupToTheCloud'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (_absorbing)
              AbsorbPointer(
                absorbing: _absorbing,
                child: Center(
                  child: LoadingAnimationWidget.fourRotatingDots(
                    color: Theme.of(context).colorScheme.secondary,
                    size: 60,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
