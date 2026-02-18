import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/database/database_helper.dart';

// Build version info - human readable timestamp
String get buildVersion {
  final now = DateTime.now();
  return 'v${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}.${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('JournalX Build: $buildVersion');

  // Request notification and SMS permissions
  await _requestPermissions();

  // Initialize database
  await DatabaseHelper.instance.database;

  // Initialize default categories and payment modes
  await DatabaseHelper.instance.initializeDefaultCategories();
  await DatabaseHelper.instance.initializeDefaultPaymentModes();

  runApp(const ProviderScope(child: JournalXApp()));
}

Future<void> _requestPermissions() async {
  // Check if we're on Android
  if (!const bool.fromEnvironment('dart.library.android')) {
    return;
  }

  try {
    // Request notification and SMS permissions
    const platform = MethodChannel('android/PERMISSIONS');
    await platform.invokeMethod('requestPermission'); // Notification
    await platform.invokeMethod('requestSmsPermission'); // SMS
  } catch (e) {
    debugPrint('Error requesting permissions: $e');
  }
}
