import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'providers.dart';

final isAdminProvider = Provider<bool>((ref) {
  final userRole = ref.watch(currentUserRoleProvider);
  return userRole == 'admin';
});
