/// Time-of-day greeting for the dashboard header.
///
/// [now] defaults to the current local time; pass a value in tests.
String timeOfDayGreeting([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}
