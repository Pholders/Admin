import 'package:flutter/material.dart';
import '../widgets/shell/app_shell.dart';
import '../widgets/tracking/delivery_tracking_body.dart';

class BillingPaymentsScreen extends StatelessWidget {
  const BillingPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      currentPage: 'Billing & Payments',
      body: DeliveryTrackingBody(
        title: 'Billing & Payments',
        subtitle: 'Track delivery status of prescription orders',
        searchHint: 'Search tracking',
      ),
    );
  }
}
