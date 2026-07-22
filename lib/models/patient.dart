import 'package:flutter/material.dart';

class Patient {
  final String name;
  final String email;
  final String phone;
  final String dateJoined;
  final String lastActivity;
  String status; // mutable: approving/suspending updates this in place
  final Color avatarColor;

  Patient({
    required this.name,
    required this.email,
    required this.phone,
    required this.dateJoined,
    required this.lastActivity,
    required this.status,
    required this.avatarColor,
  });
}
