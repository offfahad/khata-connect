import 'package:cron/cron.dart';
import 'package:khata_connect/helpers/firebaseBackup.dart';
import 'package:shared_preferences/shared_preferences.dart';

void autoBackupData(String taskId) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? lastBackup = prefs.getString('last_backup');
  DateTime lastBackupDate = DateTime.now();

  if (lastBackup != null) {
    lastBackupDate = DateTime.parse(lastBackup);
  }

  final DateTime todayDate = DateTime.now();
  if (todayDate.difference(lastBackupDate).inDays > 7) {
    final cron = Cron();
    cron.schedule(Schedule.parse('8-11 * * * *'), () async {
      await FirebaseBackup().backupAllData();
      await prefs.setString('last_backup', todayDate.toString());
    });
  }

  print('[BackgroundFetch] Headless event received.');
  //BackgroundFetch.finish(taskId);
}
