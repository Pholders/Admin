import 'package:flutter/material.dart';

/// Tracks which sidebar route is active. Swap this out for go_router /
/// Navigator 2.0 later if the app grows real routing needs — for now it's
/// simple enough to drive a body-switch in the shell.
class NavigationProvider extends ChangeNotifier {
  String _currentRoute = 'dashboard';

  String get currentRoute => _currentRoute;

  void goTo(String route) {
    if (route == _currentRoute) return;
    _currentRoute = route;
    notifyListeners();
  }
}
