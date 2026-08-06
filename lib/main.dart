import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes/routes.dart';
import 'utils/theme.dart';

void main() {
  runApp(
    // Wrap the app in ProviderScope for Riverpod state management
    const ProviderScope(
      child: RoamWiseApp(),
    ),
  );
}

class RoamWiseApp extends StatelessWidget {
  const RoamWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoamWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
