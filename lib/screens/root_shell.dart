import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:pholders_admin/store.dart';
import 'account_screen.dart';
import 'admin_tools_screen.dart';
import 'agreements_screen.dart';
import 'all_orders_screen.dart';
import 'claim_routing_screen.dart';
import 'compliance_screen.dart';
import 'partner_groups_screen.dart';
import 'security_screens.dart';
import 'billing_payments_screen.dart';
import 'dashboard_screen.dart';
import 'doctors_screen.dart';
import 'help_center_screen.dart';
import 'patients_screen.dart';
import 'payment_gateway_screen.dart';
import 'pharmacies_screen.dart';
import 'returns_screen.dart';
import 'settings_screen.dart';
import 'tracking_screen.dart';

/// The single widget mounted by main.dart. It watches which sidebar route
/// is active and swaps in the matching screen — this is what makes the
/// sidebar navigation actually work end-to-end.
class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, String>(
      converter: (store) => store.state.navigationState.currentRoute,
      distinct: true,
      builder: (context, route) {
        switch (route) {
          case 'dashboard':
            return const DashboardScreen();
          case 'patients':
            return const PatientsScreen();
          case 'all_orders':
            return const AllOrdersScreen();
          case 'returns':
            return const ReturnsScreen();
          case 'doctors':
            return const DoctorsScreen();
          case 'pharmacies':
            return const PharmaciesScreen();
          case 'tracking':
            return const TrackingScreen();
          case 'billing':
            return const BillingPaymentsScreen();
          case 'settings':
            return const SettingsScreen();
          case 'payment_gateways':
            return const PaymentGatewayScreen();
          case 'help_center':
            return const HelpCenterScreen();
          case 'partner_groups':
            return const PartnerGroupsScreen();
          case 'agreements':
            return const AgreementsScreen();
          case 'compliance':
            return const ComplianceScreen();
          case 'claim_routing':
            return const ClaimRoutingScreen();
          case 'security':
            return const SecurityOverviewScreen();
          case 'login_locations':
            return const LoginLocationsScreen();
          case 'account':
            return const AccountScreen();
          case 'admin_tools':
            return const AdminToolsScreen();
          default:
            return const DashboardScreen();
        }
      },
    );
  }
}
