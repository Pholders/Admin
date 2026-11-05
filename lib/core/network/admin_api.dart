import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import '../error/failures.dart';
import 'api_client.dart';
import 'api_error_message.dart';

/// Authenticated calls to the admin-only endpoints.
///
/// The bearer token is attached per request rather than through a shared Dio
/// interceptor: the sign-in endpoints sit behind `preventAuthenticated` and
/// refuse any request that already carries a valid token, so the shared
/// [ApiClient] must stay token-free.
///
/// Every method returns the response's `data` field when there is one, and the
/// whole body otherwise (the Stripe test, for one, answers without `data`).
/// Failures are thrown as [ServerFailure] carrying the server's own message.
class AdminApi {
  AdminApi({required this.apiClient, required this.secureStorage});

  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;

  Future<Options> _auth() async {
    final token = await secureStorage.read(key: AppConstants.tokenStorageKey);
    return Options(headers: {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    });
  }

  /// Drops null and empty-string values so optional filters are left out of
  /// the query string entirely instead of being sent as `status=`.
  static Map<String, dynamic>? _clean(Map<String, dynamic>? params) {
    if (params == null) return null;
    return {
      for (final e in params.entries)
        if (e.value != null && e.value.toString().isNotEmpty) e.key: e.value,
    };
  }

  static dynamic _unwrap(Response response) {
    final body = response.data;
    if (body is Map && body.containsKey('data')) return body['data'];
    return body;
  }

  Future<T> _send<T>(
    Future<Response> Function(Options options) request,
    String fallback,
  ) async {
    try {
      final response = await request(await _auth());
      return _unwrap(response) as T;
    } on Failure {
      rethrow;
    } on Exception catch (e) {
      throw _failureFrom(e, fallback);
    }
  }

  static Failure _failureFrom(Exception e, String fallback) {
    if (e is DioException && e.response?.statusCode == 401) {
      return const UnauthorizedFailure();
    }
    return ServerFailure(apiErrorMessage(e, fallback: fallback));
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => _send(
        (o) => apiClient.dio
            .get(path, queryParameters: _clean(query), options: o),
        'Could not load this data. Please try again.',
      );

  Future<dynamic> post(String path, {Object? body}) => _send(
        (o) => apiClient.dio.post(path, data: body ?? {}, options: o),
        'The request failed. Please try again.',
      );

  Future<dynamic> put(String path, {Object? body}) => _send(
        (o) => apiClient.dio.put(path, data: body ?? {}, options: o),
        'Could not save the changes. Please try again.',
      );

  Future<dynamic> patch(String path, {Object? body}) => _send(
        (o) => apiClient.dio.patch(path, data: body ?? {}, options: o),
        'Could not save the changes. Please try again.',
      );

  Future<dynamic> delete(String path) => _send(
        (o) => apiClient.dio.delete(path, options: o),
        'Could not remove that. Please try again.',
      );

  /// Like [get], but returns the raw body. Needed where the payload is not
  /// under `data`, or where the status code carries the answer (the Stripe
  /// test reports a failed connection as a 500 with an `error` field).
  Future<Map<String, dynamic>> getRaw(String path,
      {Map<String, dynamic>? query}) async {
    try {
      final response = await apiClient.dio.get(path,
          queryParameters: _clean(query), options: await _auth());
      final body = response.data;
      return body is Map ? Map<String, dynamic>.from(body) : {'data': body};
    } on DioException catch (e) {
      final body = e.response?.data;
      if (e.response?.statusCode != 401 && body is Map) {
        return Map<String, dynamic>.from(body);
      }
      throw _failureFrom(e, 'The request failed. Please try again.');
    }
  }

  // ─── Account ────────────────────────────────────────────────────────────────
  Future<dynamic> getProfile() => get('/users/admin/profile');
  Future<dynamic> updateProfile(Map<String, dynamic> body) =>
      put('/users/admin/profile', body: body);
  Future<dynamic> getSessions() => get('/users/admin/sessions');
  Future<dynamic> getActivityLog({int limit = 50}) =>
      get('/users/admin/activity-log', query: {'limit': limit});

  // ─── Pharmacies ─────────────────────────────────────────────────────────────
  /// `{total, limit, offset, pharmacies}`. The server caps [limit] at 200 and
  /// filters [status] in SQL, so `total` counts every match.
  Future<dynamic> listPharmacies({int limit = 200, int offset = 0, String? status}) =>
      get('/users/admin/pharmacies',
          query: {'limit': limit, 'offset': offset, 'status': status});
  Future<dynamic> getPharmacy(Object id) => get('/users/admin/pharmacies/$id');
  Future<dynamic> setPharmacyStatus(Object pharmacyId, String status) =>
      patch('/users/admin/pharmacies/$pharmacyId/status',
          body: {'status': status});

  // ─── Patients & doctors ─────────────────────────────────────────────────────
  /// `{total, limit, offset, patients}`. The server caps [limit] at 200.
  Future<dynamic> listPatients({int limit = 200, int offset = 0, String? status}) =>
      get('/users/admin/patients',
          query: {'limit': limit, 'offset': offset, 'status': status});

  /// Audit-logged on the server as `patient_record_viewed`.
  Future<dynamic> getPatient(Object id) => get('/users/admin/patients/$id');
  Future<dynamic> setPatientStatus(Object id, String status) =>
      patch('/users/admin/patients/$id/status', body: {'status': status});

  /// `{total, limit, offset, doctors}`. The server caps [limit] at 200.
  Future<dynamic> listDoctors({int limit = 200, int offset = 0, String? status}) =>
      get('/users/admin/doctors',
          query: {'limit': limit, 'offset': offset, 'status': status});
  Future<dynamic> getDoctor(Object id) => get('/users/admin/doctors/$id');
  Future<dynamic> setDoctorStatus(Object id, String status) =>
      patch('/users/admin/doctors/$id/status', body: {'status': status});

  // ─── Dashboard ──────────────────────────────────────────────────────────────
  /// `{counts, revenue, alerts}` — see backend models/AdminDashboard.js.
  Future<dynamic> dashboardSummary() => get('/users/admin/dashboard/summary');

  /// `{range, buckets: [{label, start, prescriptions, orders}]}`; [range] is
  /// `daily` (30 days), `monthly` (this year) or `yearly` (5 years).
  Future<dynamic> dashboardActivity({String range = 'monthly'}) =>
      get('/users/admin/dashboard/activity', query: {'range': range});

  /// `{role, users: [{id, role, name, email, status, profile_image, created_at}]}`.
  /// `id` is unique only together with `role`.
  Future<dynamic> recentUsers({String role = 'all', int limit = 10}) =>
      get('/users/admin/users/recent', query: {'role': role, 'limit': limit});

  // ─── Security ───────────────────────────────────────────────────────────────
  Future<dynamic> securityDashboard({int hours = 24}) =>
      get('/users/admin/security/dashboard', query: {'hours': hours});
  Future<dynamic> userLocations({required String userId, int days = 30}) =>
      get('/users/admin/security/user-locations',
          query: {'user_id': userId, 'days': days});

  // ─── Partnership groups ─────────────────────────────────────────────────────
  Future<dynamic> listGroups({String? tier, bool isActive = true}) =>
      get('/users/partnerships/groups', query: {
        'tier': tier,
        // Always sent: the backend turns a missing value into `false` and
        // would return only the inactive groups.
        'is_active': isActive.toString(),
        'limit': 100,
      });
  Future<dynamic> searchGroups(String q) =>
      get('/users/partnerships/groups/search', query: {'q': q});
  Future<dynamic> getGroup(Object id) => get('/users/partnerships/groups/$id');
  Future<dynamic> createGroup(Map<String, dynamic> body) =>
      post('/users/partnerships/groups', body: body);
  Future<dynamic> updateGroup(Object id, Map<String, dynamic> body) =>
      put('/users/partnerships/groups/$id', body: body);
  Future<dynamic> addPharmacyToGroup(Object groupId, Object pharmacyId,
          {bool isPrimary = true}) =>
      post('/users/partnerships/groups/$groupId/pharmacies',
          body: {'pharmacy_id': pharmacyId, 'is_primary': isPrimary});
  Future<dynamic> removePharmacyFromGroup(Object groupId, Object pharmacyId) =>
      delete('/users/partnerships/groups/$groupId/pharmacies/$pharmacyId');

  // ─── Partnership agreements ─────────────────────────────────────────────────
  Future<dynamic> listAgreements({String? status, String? entityType}) =>
      get('/users/partnerships/agreements', query: {
        'status': status,
        'entity_type': entityType,
        'limit': 100,
      });
  Future<dynamic> expiringAgreements({int days = 30}) =>
      get('/users/partnerships/agreements/expiring', query: {'days': days});
  Future<dynamic> getAgreement(Object id) =>
      get('/users/partnerships/agreements/$id');
  Future<dynamic> createAgreement(Map<String, dynamic> body) =>
      post('/users/partnerships/agreements', body: body);
  Future<dynamic> updateAgreement(Object id, Map<String, dynamic> body) =>
      put('/users/partnerships/agreements/$id', body: body);
  Future<dynamic> activateAgreement(Object id) =>
      post('/users/partnerships/agreements/$id/activate');
  Future<dynamic> suspendAgreement(Object id) =>
      post('/users/partnerships/agreements/$id/suspend');

  // ─── Compliance & routing ───────────────────────────────────────────────────
  Future<dynamic> complianceDashboard() =>
      get('/users/partnerships/compliance/dashboard');
  Future<dynamic> pharmacyCompliance(Object pharmacyId) =>
      get('/users/partnerships/compliance/pharmacy/$pharmacyId');
  Future<dynamic> complianceReport(
          {required String startDate, required String endDate}) =>
      get('/users/partnerships/compliance/report',
          query: {'start_date': startDate, 'end_date': endDate});
  Future<dynamic> routingCandidates(
          {required double latitude, required double longitude}) =>
      get('/users/partnerships/routing/candidates',
          query: {'latitude': latitude, 'longitude': longitude});
  Future<dynamic> routingStatistics({String? startDate, String? endDate}) =>
      get('/users/partnerships/routing/statistics',
          query: {'start_date': startDate, 'end_date': endDate});
  Future<dynamic> routingByTier() =>
      get('/users/partnerships/routing/by-tier');

  // ─── Maintenance ────────────────────────────────────────────────────────────
  Future<dynamic> autoCancelExpiredAppointments({int timeoutMinutes = 30}) =>
      post('/appointments/auto-cancel-expired',
          body: {'timeoutMinutes': timeoutMinutes});
  Future<dynamic> revertPrescriptionClaim(String prescriptionId,
          {required String reason}) =>
      post('/prescriptions/$prescriptionId/revert-claim',
          body: {'reason': reason});
  Future<Map<String, dynamic>> testStripe() =>
      getRaw('/users/payments/stripe/test');
  Future<dynamic> systemLogs({int lines = 100}) =>
      get('/system/logs', query: {'lines': lines});
}
