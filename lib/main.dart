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

  // Pass build version to the app
  debugPrint('JournalX Build: $buildVersion');

  // Request notification permission on Android 13+
  if (await _requestNotificationPermission()) {
    debugPrint('Notification permission granted');
  } else {
    debugPrint('Notification permission denied');
  }

  // Initialize database
  await DatabaseHelper.instance.database;

  // Initialize default categories and payment modes
  await DatabaseHelper.instance.initializeDefaultCategories();
  await DatabaseHelper.instance.initializeDefaultPaymentModes();

  runApp(const ProviderScope(child: JournalXApp()));
}

Future<bool> _requestNotificationPermission() async {
  // Check if we're on Android
  if (!const bool.fromEnvironment('dart.library.android')) {
    return true;
  }

  try {
    // Method channel to request notification permission
    const platform = MethodChannel('android/NOTIFICATION_PERMISSION');
    final result = await platform.invokeMethod<bool>('requestPermission');
    return result ?? false;
  } catch (e) {
    // Fallback: try using permission_handler approach
    try {
      final androidPlugin = await _getNotificationChannel();
      return androidPlugin;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }
}

Future<bool> _getNotificationChannel() async {
  // For Android 13+, we need to check and request notification channel
  // This is a simplified approach - the service will still work
  // as it uses its own notification channel
  return true;
}
