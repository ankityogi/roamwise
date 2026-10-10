import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/hotel_search_screen.dart';
import '../screens/my_bookings_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String hotels = '/hotels';
  static const String myBookings = '/my-bookings';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      auth: (context) => const AuthScreen(),
      home: (context) => const HomeScreen(),
      hotels: (context) => const HotelSearchScreen(),
      myBookings: (context) => const MyBookingsScreen(),
    };
  }
}
