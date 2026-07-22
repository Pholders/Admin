class TrackingOrder {
  final String orderId;
  final String patient;
  final String pharmacy;
  final String courier;
  final String trackingNumber;
  String status; // mutable: action menu updates this
  String eta; // mutable: e.g. "2 hrs", "1 day", or "-" once delivered/failed

  TrackingOrder({
    required this.orderId,
    required this.patient,
    required this.pharmacy,
    required this.courier,
    required this.trackingNumber,
    required this.status,
    required this.eta,
  });
}
