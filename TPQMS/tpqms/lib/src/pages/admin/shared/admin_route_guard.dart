// admin_route_guard.dart
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/providers/admin_providers/admin_auth_provider.dart';

class AdminRouteGuard {
  static Future<bool> checkAccess(BuildContext context) async {
    final adminProvider =
        Provider.of<AdminAuthProvider>(context, listen: false);
    if (adminProvider.currentAdmin == null) {
      // Redirect to login
      Navigator.of(context).pushReplacementNamed(Constants.LoginPage);
      return false;
    }
    return true;
  }
}
