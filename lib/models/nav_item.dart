import 'package:flutter/material.dart';

/// A single clickable row in the sidebar (e.g. "Dashboard", "Patients").
class NavItem {
  final String label;
  final IconData? icon; // only top-level section headers show an icon
  final String route;

  const NavItem({required this.label, required this.route, this.icon});
}

/// A group in the sidebar, e.g. "Users" containing Patients/Doctors/Pharmacies.
class NavSection {
  final String title;
  final IconData icon;
  final List<NavItem> items;

  const NavSection({
    required this.title,
    required this.icon,
    required this.items,
  });
}
