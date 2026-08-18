import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_admin/store.dart';

void main() {
  group('navigationReducer', () {
    test('starts on the dashboard route', () {
      expect(const NavigationState().currentRoute, 'dashboard');
    });

    test('changes the selected route', () {
      final nextState = navigationReducer(
        const NavigationState(),
        const NavigateToAction('patients'),
      );

      expect(nextState.currentRoute, 'patients');
    });

    test('returns the same state when the selected route is unchanged', () {
      const state = NavigationState(currentRoute: 'patients');

      expect(
        identical(
          navigationReducer(state, const NavigateToAction('patients')),
          state,
        ),
        isTrue,
      );
    });
  });
}
