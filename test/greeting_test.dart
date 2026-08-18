import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_admin/core/utils/greeting.dart';

void main() {
  test('timeOfDayGreeting covers each part of the day', () {
    expect(timeOfDayGreeting(DateTime(2026, 1, 1, 0)), 'Good Morning');
    expect(timeOfDayGreeting(DateTime(2026, 1, 1, 11, 59)), 'Good Morning');
    expect(timeOfDayGreeting(DateTime(2026, 1, 1, 12)), 'Good Afternoon');
    expect(timeOfDayGreeting(DateTime(2026, 1, 1, 16, 59)), 'Good Afternoon');
    expect(timeOfDayGreeting(DateTime(2026, 1, 1, 17)), 'Good Evening');
    expect(timeOfDayGreeting(DateTime(2026, 1, 1, 23, 59)), 'Good Evening');
  });
}
