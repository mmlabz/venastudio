import 'dart:io';

import 'package:venastudio/common.dart';

class LocalStorage {
  factory LocalStorage() => _instance;
  LocalStorage._();
  static final LocalStorage _instance = LocalStorage._();
  static LocalStorage get instance => _instance;
  late final NoSQLDb _nosql;
  static NoSQLDb get nosql => instance._nosql;
  String? kAppFolderPath;

  Future<void> initialize() async {
    try {
      _nosql = NoSQLDb(preferences: await SharedPreferences.getInstance());

      try {
        if (Platform.isWindows) {
          kAppFolderPath = await getApplicationSupportDirectory().then(
            (value) => value.path,
          );
          await _backupPreferences();
        }
      } catch (e) {}
    } catch (e) {
      if (Platform.isWindows) {
        try {
          await _restorePreferencesFromBackup();
          _nosql = NoSQLDb(preferences: await SharedPreferences.getInstance());
        } catch (e) {}
      }
    }
  }

  Future<void> _backupPreferences() async {
    if (kAppFolderPath != null) {
      try {
        final String original = '$kAppFolderPath\\shared_preferences.json';
        final String backup = '$kAppFolderPath\\shared_preferences_backup.json';

        if (await File(backup).exists()) {
          await File(backup).delete(recursive: true);
        }
        await File(original).copy(backup);
      } catch (_) {
        /* Do nothing */
      }
    }
  }

  /// Removes current version of shared_preferences file and restores previous
  /// user settings from a backup file (if it exists).
  Future<void> _restorePreferencesFromBackup() async {
    if (kAppFolderPath != null) {
      try {
        final String original = '$kAppFolderPath\\shared_preferences.json';
        final String backup = '$kAppFolderPath\\shared_preferences_backup.json';

        await File(original).delete(recursive: true);

        if (await File(backup).exists()) {
          // Check if current backup copy is not broken by looking for letters and "
          // symbol in it to replace it as an original Settings file
          final String preferences = await File(backup).readAsString();
          if (preferences.contains('"') &&
              preferences.contains(RegExp('[A-z]'))) {
            await File(backup).copy(original);
          }
        }
      } catch (_) {
        /* Do nothing */
      }
    }
  }
}
