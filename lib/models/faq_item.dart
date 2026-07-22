class FaqItem {
  final String question;
  final String category;
  String status; // mutable: Publish/Unpublish action updates this

  FaqItem({required this.question, required this.category, required this.status});
}
