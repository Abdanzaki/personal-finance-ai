import 'package:flutter_riverpod/flutter_riverpod.dart';

final isDarkModeProvider = StateProvider<bool>((ref) {
  return false;
});

final notificationsEnabledProvider = StateProvider<bool>((ref) {
  return true;
});

final biometricsEnabledProvider = StateProvider<bool>((ref) {
  return false;
});
