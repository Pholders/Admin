class PrescriptionOrder {
  final String orderId;
  final String patient;
  final String doctor;
  final String pharmacy;
  final String date;
  String status; // mutable: status-update action changes this
  final double total;

  PrescriptionOrder({
    required this.orderId,
    required this.patient,
    required this.doctor,
    required this.pharmacy,
    required this.date,
    required this.status,
    required this.total,
  });
}
