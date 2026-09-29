/// Coercions for JSON coming out of the Postgres-backed API.
///
/// `node-postgres` returns `DECIMAL`, `NUMERIC` and `BIGINT` columns — and
/// every `COUNT(*)`/`AVG(...)` aggregate — as **strings**, not numbers, to
/// avoid precision loss. So `commission_rate` arrives as `"12.50"` and
/// `pharmacy_count` as `"3"`. Parsing with a plain `as int` would throw on
/// every one of them.
library;

int? asIntOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString()) ??
      double.tryParse(value.toString())?.round();
}

int asInt(Object? value, {int fallback = 0}) =>
    asIntOrNull(value) ?? fallback;

double? asDoubleOrNull(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

double asDouble(Object? value, {double fallback = 0}) =>
    asDoubleOrNull(value) ?? fallback;

bool asBool(Object? value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  final text = value.toString().toLowerCase();
  if (text == 'true' || text == 't' || text == '1') return true;
  if (text == 'false' || text == 'f' || text == '0') return false;
  return fallback;
}

/// Trimmed string, or null when absent or blank.
String? asStringOrNull(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String asString(Object? value, {String fallback = ''}) =>
    asStringOrNull(value) ?? fallback;

/// Parses a timestamp or `DATE` column.
///
/// Postgres `DATE` serialises as `2026-03-12T00:00:00.000Z` and `TIMESTAMP`
/// without a zone as `2026-03-12T08:14:22.104Z`; both parse cleanly. The
/// result is converted to local time so dates render in the admin's zone.
DateTime? asDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  return DateTime.tryParse(value.toString())?.toLocal();
}

/// A list of JSON objects under [key], tolerating a missing or wrongly
/// shaped value.
List<Map<String, dynamic>> asObjectList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

/// A nested JSON object, or `{}`.
Map<String, dynamic> asObject(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}
