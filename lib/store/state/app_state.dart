import 'package:equatable/equatable.dart';

import 'admin_state.dart';
import 'auth_state.dart';
import 'navigation_state.dart';

/// Root Redux state composed from each feature state slice.
class AppState extends Equatable {
  final AuthState authState;
  final NavigationState navigationState;
  final AdminState adminState;

  const AppState({
    required this.authState,
    required this.navigationState,
    this.adminState = const AdminState(),
  });

  factory AppState.initial() => AppState(
        authState: AuthState.initial(),
        navigationState: const NavigationState(),
        adminState: AdminState.initial(),
      );

  @override
  List<Object?> get props => [authState, navigationState, adminState];
}
