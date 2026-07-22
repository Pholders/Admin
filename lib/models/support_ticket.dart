class SupportTicket {
  final String ticketId;
  final String customer;
  final String subject;
  final String category;
  String priority; // mutable
  String status; // mutable: action menu updates this
  final String lastUpdated;

  SupportTicket({
    required this.ticketId,
    required this.customer,
    required this.subject,
    required this.category,
    required this.priority,
    required this.status,
    required this.lastUpdated,
  });
}
