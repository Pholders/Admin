import 'package:flutter/material.dart';

class Doctor {
  final String name;
  final String email;
  final String specialization;
  String status; // mutable: approve/suspend actions update this
  final String joinedOn;
  final Color avatarColor;

  Doctor({
    required this.name,
    required this.email,
    required this.specialization,
    required this.status,
    required this.joinedOn,
    required this.avatarColor,
  });
}
