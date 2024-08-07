import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as pathx;
import 'package:path_provider/path_provider.dart';

class FirebaseBackup {
  Future<bool> backupAllData() async {
    try {
      await Firebase.initializeApp();

      final FirebaseStorage storage = FirebaseStorage.instance;

      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String dbPath = pathx.join(documentsDirectory.path, 'khataConnect.db');
      File file = File(dbPath);

      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      final Reference ref = storage
          .ref()
          .child('khata-connect-database')
          .child(user.uid)
          .child('khataConnect.db');

      await ref.putFile(file);
      await Future.delayed(const Duration(seconds: 5)); // Delay for upload completion
      return true;
    } catch (e) {
      print('Error backing up data: $e');
      return false;
    }
  }

  Future<bool> restoreAllData() async {
    try {
      await Firebase.initializeApp();

      final FirebaseStorage storage = FirebaseStorage.instance;

      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      final Reference ref = storage
          .ref()
          .child('khata-connect-database')
          .child(user.uid)
          .child('khataConnect.db');

      final String url = await ref.getDownloadURL();
      final http.Response downloadData = await http.get(Uri.parse(url));

      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String dbPath = pathx.join(documentsDirectory.path, 'khataConnect.db');
      File file = File(dbPath);

      await file.create(recursive: true);
      await file.writeAsBytes(downloadData.bodyBytes);
      return true;
    } catch (e) {
      print('Error restoring data: $e');
      return false;
    }
  }

  Future<bool> downloadBackup() async {
    try {
      await Firebase.initializeApp();

      final FirebaseStorage storage = FirebaseStorage.instance;

      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      final Reference ref = storage
          .ref()
          .child('khata-connect-database')
          .child(user.uid)
          .child('khataConnect.db');

      final String url = await ref.getDownloadURL();
      final http.Response downloadData = await http.get(Uri.parse(url));

      final Directory downloadDirectory = Directory('/storage/emulated/0/Download');
      final File tempFile = File(pathx.join(downloadDirectory.path, 'khataConnect.db'));

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      await tempFile.create();
      await tempFile.writeAsBytes(downloadData.bodyBytes);

      return true;
    } catch (e) {
      print('Error downloading backup: $e');
      return false;
    }
  }
}
