import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class Logger {
  static void debug(String message, [dynamic error]) {
    if (kDebugMode && AppConfig.isDebugMode) {
      debugPrint('[DEBUG] $message${error != null ? ': $error' : ''}');
    }
  }
  
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }
  
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('[WARNING] $message');
    }
  }
  
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message${error != null ? ': $error' : ''}');
      if (stackTrace != null && AppConfig.isDebugMode) {
        debugPrint(stackTrace.toString());
      }
    }
  }
}