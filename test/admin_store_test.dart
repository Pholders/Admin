import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_admin/core/error/failures.dart';
import 'package:pholders_admin/core/network/admin_api.dart';
import 'package:pholders_admin/core/network/api_client.dart';
import 'package:pholders_admin/store.dart';
import 'package:redux/redux.dart';

/// Answers from canned data instead of the network.
class _FakeAdminApi extends AdminApi {
  _FakeAdminApi()
      : super(
          apiClient: ApiClient(),
          secureStorage: const FlutterSecureStorage(),
        );

  final calls = <String>[];
  Object? groupsError;
  final pharmacyStatus = <Object, String>{'7': 'active'};
  final groupResponses = <String, Completer<dynamic>>{};

  @override
  Future<dynamic> listPharmacies({int limit = 200, int offset = 0, String? status}) async {
    calls.add('listPharmacies');
    return {
      'total': 1,
      'pharmacies': [
        {'id': 7, 'status': pharmacyStatus['7']},
      ],
    };
  }

  @override
  Future<dynamic> setPharmacyStatus(Object pharmacyId, String status) async {
    calls.add('setPharmacyStatus $pharmacyId $status');
    pharmacyStatus['$pharmacyId'] = status;
    return {'id': pharmacyId, 'status': status};
  }

  @override
  Future<dynamic> listGroups({String? tier, bool isActive = true}) async {
    calls.add('listGroups isActive=$isActive');
    if (groupsError != null) throw groupsError!;
    return [];
  }

  @override
  Future<dynamic> getGroup(Object id) {
    calls.add('getGroup $id');
    return (groupResponses['$id'] = Completer()).future;
  }
}

Store<AppState> _store(_FakeAdminApi api) => Store<AppState>(
      appReducer,
      initialState: AppState.initial().copyWith(
        authState: const AuthState(token: 't', role: 'admin'),
      ),
      middleware: AdminMiddleware(api: api).middleware,
    );

extension on AppState {
  AppState copyWith({AuthState? authState}) => AppState(
        authState: authState ?? this.authState,
        navigationState: navigationState,
        adminState: adminState,
      );
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('admin store', () {
    test('a fetch moves loading → success with the response data', () async {
      final api = _FakeAdminApi();
      final store = _store(api);

      store.dispatch(const FetchAdminResourceAction(AdminResource.pharmacies));
      expect(store.state.adminState.of(AdminResource.pharmacies).isLoading,
          isTrue);

      await _settle();
      final slot = store.state.adminState.of(AdminResource.pharmacies);
      expect(slot.status, LoadStatus.success);
      expect(slot.data['pharmacies'], hasLength(1));
    });

    test('groups are always requested with is_active, defaulting to true',
        () async {
      final api = _FakeAdminApi();
      final store = _store(api);

      store.dispatch(const FetchAdminResourceAction(AdminResource.groups));
      store.dispatch(const FetchAdminResourceAction(AdminResource.groups,
          params: {'is_active': false}));
      await _settle();

      expect(api.calls,
          ['listGroups isActive=true', 'listGroups isActive=false']);
    });

    test('a slow reply for an older request does not overwrite a newer one',
        () async {
      final api = _FakeAdminApi();
      final store = _store(api);

      store.dispatch(const FetchAdminResourceAction(AdminResource.groupDetail,
          params: {'id': 3}));
      store.dispatch(const FetchAdminResourceAction(AdminResource.groupDetail,
          params: {'id': 5}));
      api.groupResponses['5']!.complete({'id': 5});
      await _settle();
      api.groupResponses['3']!.complete({'id': 3});
      await _settle();

      expect(store.state.adminState.of(AdminResource.groupDetail).data,
          {'id': 5});
    });

    test('a write completes its completer and reloads what it changed',
        () async {
      final api = _FakeAdminApi();
      final store = _store(api);
      store.dispatch(const FetchAdminResourceAction(AdminResource.pharmacies,
          params: {'limit': 100}));
      await _settle();

      final done = Completer<dynamic>();
      store.dispatch(SetPharmacyStatusAction('7', 'suspended', completer: done));
      expect(store.state.adminState.isPending('pharmacy.7.status'), isTrue);

      await done.future;
      await _settle();

      expect(store.state.adminState.isPending('pharmacy.7.status'), isFalse);
      expect(api.calls, [
        'listPharmacies',
        'setPharmacyStatus 7 suspended',
        'listPharmacies',
      ]);
      final slot = store.state.adminState.of(AdminResource.pharmacies);
      expect(slot.params, {'limit': 100}, reason: 'reload keeps the filters');
      expect(slot.data['pharmacies'][0]['status'], 'suspended');
    });

    test('a 401 ends the session and clears admin data', () async {
      final api = _FakeAdminApi();
      final store = _store(api);
      store.dispatch(const FetchAdminResourceAction(AdminResource.pharmacies));
      await _settle();

      api.groupsError = const UnauthorizedFailure();
      store.dispatch(const FetchAdminResourceAction(AdminResource.groups));
      await _settle();

      expect(store.state.authState.isAuthenticated, isFalse);
      expect(store.state.adminState.of(AdminResource.pharmacies).isIdle,
          isTrue);
    });

    test('a failed fetch keeps the server message', () async {
      final api = _FakeAdminApi()
        ..groupsError = const ServerFailure('Invalid tier');
      final store = _store(api);

      store.dispatch(const FetchAdminResourceAction(AdminResource.groups));
      await _settle();

      final slot = store.state.adminState.of(AdminResource.groups);
      expect(slot.hasError, isTrue);
      expect(slot.error, 'Invalid tier');
    });
  });
}
