import 'package:flutter/material.dart';

class Pharmacy {
  final String name;
  final String ownerContact;
  final String email;
  String status; // mutable: approve/suspend actions update this
  final String joinedOn;
  final Color avatarColor;

  Pharmacy({
    required this.name,
    required this.ownerContact,
    required this.email,
    required this.status,
    required this.joinedOn,
    required this.avatarColor,
  });
}
