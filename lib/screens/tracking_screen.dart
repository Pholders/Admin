import 'package:flutter/material.dart';
import '../widgets/shell/app_shell.dart';
import '../widgets/tracking/delivery_tracking_body.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      currentPage: 'Prescriptions',
      body: DeliveryTrackingBody(
        title: 'Tracking',
        subtitle: 'Track delivery status of prescription orders',
        searchHint: 'Search tracking',
      ),
    );
  }
}
