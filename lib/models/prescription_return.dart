class PrescriptionReturn {
  final String returnId;
  final String orderId;
  final String patient;
  final String pharmacy;
  final String date;
  final String reason;
  String status; // mutable: Approve/Reject actions change this
  final double total;

  PrescriptionReturn({
    required this.returnId,
    required this.orderId,
    required this.patient,
    required this.pharmacy,
    required this.date,
    required this.reason,
    required this.status,
    required this.total,
  });
}
