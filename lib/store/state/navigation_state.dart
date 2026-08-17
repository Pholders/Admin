import 'package:equatable/equatable.dart';

/// The selected sidebar screen within the authenticated shell.
class NavigationState extends Equatable {
  static const dashboardRoute = 'dashboard';

  final String currentRoute;

  const NavigationState({this.currentRoute = dashboardRoute});

  @override
  List<Object?> get props => [currentRoute];
}
