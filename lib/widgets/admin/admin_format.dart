import 'package:intl/intl.dart';

/// Helpers for showing raw API JSON. Several admin payloads are SQL rows whose
/// columns follow the backend's queries, so screens read them as maps rather
/// than through model classes.

/// `"avg_compliance_score"` → `"Avg Compliance Score"`, `"pharmacyId"` →
/// `"Pharmacy Id"`.
String humanize(String key) {
  final spaced = key
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .trim();
  if (spaced.isEmpty) return key;
  return spaced
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

final _isoDateTime = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}');
final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

final _dateTimeFormat = DateFormat('d MMM yyyy, HH:mm');
final _dateFormat = DateFormat('d MMM yyyy');
final _apiDateFormat = DateFormat('yyyy-MM-dd');

/// Readable text for any JSON value.
String formatValue(dynamic value) {
  if (value == null) return '—';
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is num) return formatNumber(value);
  if (value is List) {
    if (value.isEmpty) return '—';
    if (value.every((e) => e is! Map && e is! List)) {
      return value.map(formatValue).join(', ');
    }
    return '${value.length} items';
  }
  if (value is Map) {
    return value.entries
        .where((e) => e.value is! Map && e.value is! List)
        .map((e) => '${humanize('${e.key}')}: ${formatValue(e.value)}')
        .join(' · ');
  }
  final text = value.toString().trim();
  if (text.isEmpty) return '—';
  if (_isoDateTime.hasMatch(text)) return formatDate(text, withTime: true);
  if (_isoDate.hasMatch(text)) return formatDate(text);
  return text;
}

/// South African Standard Time is UTC+2 all year (no daylight saving), so
/// `Africa/Johannesburg` is a fixed offset and needs no time-zone database.
const sastOffset = Duration(hours: 2);

/// [instant] as a wall-clock time in Africa/Johannesburg. The result is a
/// "UTC" [DateTime] holding SAST fields, for formatting only.
DateTime toSast(DateTime instant) => instant.toUtc().add(sastOffset);

/// `"2026-03-12T08:30:00.000Z"` → `"12 Mar 2026, 10:30"` in Africa/Johannesburg
/// time, whatever zone the admin's device is in — the backend's dates and
/// filters are all South African.
String formatDate(dynamic value, {bool withTime = false}) {
  if (value == null) return '—';
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();
  // Date-only values (e.g. `appointment_date`) have no zone: shifting them
  // could move them to the previous day.
  final wall = _isoDate.hasMatch(value.toString()) ? parsed : toSast(parsed);
  return (withTime ? _dateTimeFormat : _dateFormat).format(wall);
}

/// The `yyyy-MM-dd` form the API expects for date fields and filters.
String apiDate(DateTime date) => _apiDateFormat.format(date);

String formatNumber(num value, {int decimals = 2}) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  // 12.50 → "12.5", 12.25 → "12.25"
  return value
      .toStringAsFixed(decimals)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// `20000` → `R20 000`, `1234.5` → `R1 234,50` (South African formatting).
String formatRand(dynamic value) {
  final n = numOf(value);
  if (n == null) return '—';
  return NumberFormat.currency(
    locale: 'en_ZA',
    symbol: 'R',
    decimalDigits: n == n.roundToDouble() ? 0 : 2,
  ).format(n);
}

/// `1234` → `1.2K`, for figures in tight spots like the donut centre.
String formatCompact(dynamic value) {
  final n = numOf(value);
  if (n == null) return '—';
  return n < 10000 ? formatNumber(n) : NumberFormat.compact().format(n);
}

/// Postgres sends DECIMAL and COUNT(*) as strings; this reads either.
num? numOf(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

String percent(dynamic value) {
  final n = numOf(value);
  return n == null ? '—' : '${formatNumber(n)}%';
}

Map<String, dynamic> mapOf(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

/// Rows from a list response. Accepts a bare list, or a map holding the list
/// under one of [keys] (e.g. `{pharmacies: [...]}`).
List<Map<String, dynamic>> recordsOf(dynamic value,
    [List<String> keys = const []]) {
  dynamic list = value;
  if (value is Map) {
    list = null;
    for (final key in keys) {
      if (value[key] is List) {
        list = value[key];
        break;
      }
    }
  }
  if (list is! List) return const [];
  return [
    for (final item in list)
      if (item is Map) Map<String, dynamic>.from(item),
  ];
}

/// `"Ada Lovelace"` from `first_name`/`last_name`, falling back through
/// [fallbacks].
String personName(Map<String, dynamic> row, {List<String> fallbacks = const []}) {
  final name = [row['first_name'], row['last_name']]
      .where((v) => v != null && v.toString().trim().isNotEmpty)
      .join(' ');
  if (name.isNotEmpty) return name;
  for (final key in fallbacks) {
    final v = row[key]?.toString().trim();
    if (v != null && v.isNotEmpty) return v;
  }
  return '—';
}
