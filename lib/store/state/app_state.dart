import 'package:equatable/equatable.dart';

import 'auth_state.dart';
import 'navigation_state.dart';

/// Root Redux state composed from each feature state slice.
class AppState extends Equatable {
  final AuthState authState;
  final NavigationState navigationState;

  const AppState({
    required this.authState,
    required this.navigationState,
  });

  factory AppState.initial() => AppState(
        authState: AuthState.initial(),
        navigationState: const NavigationState(),
      );

  @override
  List<Object?> get props => [authState, navigationState];
}
