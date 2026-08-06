import 'dart:io';

// Configuration helper supplying the base backend server path depending on active platform
class AppConfig {
  static String get baseUrl {
    // If running on Android Emulator, target the host loopback IP 10.0.2.2
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    // For iOS simulator or desktop/web platforms, target localhost 127.0.0.1
    return 'http://localhost:5000/api';
  }
}
