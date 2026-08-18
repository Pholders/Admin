import 'package:flutter/widgets.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import 'package:pholders_admin/core/routing/app_routes.dart';
import 'package:pholders_admin/store/actions/auth_actions.dart';
import 'package:pholders_admin/store.dart';

/// Signs the current admin out and returns them to the login page.
void performLogout(BuildContext context) {
  StoreProvider.of<AppState>(context).dispatch(const LogoutAction());
  context.go(AppRoutes.adminLogin);
}
