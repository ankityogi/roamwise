import 'package:flutter_riverpod/flutter_riverpod.dart';

// Riverpod provider to manage the active bottom navigation tab index
final activeTabProvider = StateProvider<int>((ref) => 0);
