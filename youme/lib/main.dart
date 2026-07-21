import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'core/utils/error_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize error logger
  ErrorLogger.init();
  FlutterError.onError = (details) {
    ErrorLogger.log('Flutter Error', details.exceptionAsString(),
        stackTrace: details.stack);
  };

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();
  } catch (e) {
    ErrorLogger.log('Firebase Init', e.toString());
  }

  runApp(const YouMeApp());
}
