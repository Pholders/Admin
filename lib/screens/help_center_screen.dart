import 'package:flutter/material.dart';
import '../models/faq_item.dart';
import '../models/support_ticket.dart';
import '../theme/app_colors.dart';
import '../widgets/common/page_header.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/common/table_cell.dart';
import '../widgets/shell/app_shell.dart';

enum _HelpTab { faqs, tickets, categories }

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  _HelpTab _tab = _HelpTab.faqs;
  String _query = '';
  String? _selectedCategory;

  static const List<String> _categories = [
    'Getting Started',
    'Orders & Prescriptions',
    'Payment & Billing',
    'Returns & Refunds',
    'Account & Security',
    'General',
  ];

  final List<FaqItem> _faqs = [
    FaqItem(question: 'How do I place a prescription order?', category: 'Orders & Prescriptions', status: 'Published'),
    FaqItem(question: 'How do I track my order?', category: 'Payment & Billing', status: 'Published'),
    FaqItem(question: 'Which payment methods are accepted?', category: 'Returns & Refunds', status: 'Published'),
    FaqItem(question: 'How do I get a refund?', category: 'Account & Security', status: 'Published'),
    FaqItem(question: 'How do I reset my password?', category: 'Orders & Prescriptions', status: 'Published'),
    FaqItem(question: 'How do I contact customer support?', category: 'General', status: 'Published'),
  ];

  final List<SupportTicket> _tickets = [
    SupportTicket(ticketId: 'TXT-2026-1868', customer: 'Maria Wilson', subject: 'Unable to track my order', category: 'Orders & Prescriptions', priority: 'High', status: 'Open', lastUpdated: '08 May 2026, 9:22 AM'),
    SupportTicket(ticketId: 'TXT-8306-1687', customer: 'Maria Wilson', subject: 'Payment failed but amount deducted', category: 'Payment & Billing', priority: 'High', status: 'In Progress', lastUpdated: '08 May 2026, 9:22 AM'),
    SupportTicket(ticketId: 'TXT-2026-1846', customer: 'Maria Wilson', subject: 'Requesting refund for returned item', category: 'Returns & Refunds', priority: 'Medium', status: 'Open', lastUpdated: '08 May 2026, 9:22 AM'),
    SupportTicket(ticketId: 'TXT-2026-1845', customer: 'Maria Wilson', subject: 'Update my account information', category: 'Account & Security', priority: 'Low', status: 'Closed', lastUpdated: '08 May 2026, 9:22 AM'),
    SupportTicket(ticketId: 'TXT-2026-1845', customer: 'Maria Wilson', subject: 'Prescription upload not working', category: 'Orders & Prescriptions', priority: 'Medium', status: 'In Progress', lastUpdated: '08 May 2026, 9:22 AM'),
  ];

  List<FaqItem> get _filteredFaqs {
    Iterable<FaqItem> list = _faqs;
    if (_selectedCategory != null) list = list.where((f) => f.category == _selectedCategory);
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((f) => f.question.toLowerCase().contains(q));
    }
    return list.toList();
  }

  List<SupportTicket> get _filteredTickets {
    if (_query.trim().isEmpty) return _tickets;
    final q = _query.toLowerCase();
    return _tickets.where((t) =>
        t.ticketId.toLowerCase().contains(q) ||
        t.customer.toLowerCase().contains(q) ||
        t.subject.toLowerCase().contains(q)).toList();
  }

  int _faqCountFor(String category) => _faqs.where((f) => f.category == category).length;
  int _ticketCountFor(String category) => _tickets.where((t) => t.category == category).length;

  void _setTab(_HelpTab tab) {
    setState(() {
      _tab = tab;
      _query = '';
    });
  }

  void _addFaq() {
    final questionController = TextEditingController();
    String category = _categories.first;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add FAQ'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(labelText: 'Question'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [for (final c in _categories) DropdownMenuItem(value: c, child: Text(c))],
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (questionController.text.trim().isEmpty) return;
                setState(() {
                  _faqs.add(FaqItem(question: questionController.text.trim(), category: category, status: 'Published'));
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFaqStatus(FaqItem faq) {
    setState(() => faq.status = faq.status == 'Published' ? 'Draft' : 'Published');
  }

  void _deleteFaq(FaqItem faq) {
    setState(() => _faqs.remove(faq));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FAQ deleted')));
  }

  void _setTicketStatus(SupportTicket ticket, String status) {
    setState(() => ticket.status = status);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ticket ${ticket.ticketId} marked as $status')));
  }

  void _exportTickets() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting ${_filteredTickets.length} tickets...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Help Center';
    final subtitle = switch (_tab) {
      _HelpTab.faqs => 'Manage frequently asked questions',
      _HelpTab.tickets => 'Manage support tickets',
      _HelpTab.categories => 'Manage FAQ and ticket categories',
    };

    return AppShell(
      currentPage: 'Help Center',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_tab == _HelpTab.faqs)
              PageHeader(
                title: title,
                subtitle: subtitle,
                searchHint: 'Search FAQs...',
                onSearchChanged: (v) => setState(() => _query = v),
                actionLabel: 'Add FAQ',
                onActionTap: _addFaq,
              )
            else if (_tab == _HelpTab.tickets)
              PageHeader(
                title: title,
                subtitle: subtitle,
                searchHint: 'Search tickets...',
                onSearchChanged: (v) => setState(() => _query = v),
                actionLabel: 'Export',
                onActionTap: _exportTickets,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            const SizedBox(height: 16),
            _TabPills(selected: _tab, onSelect: _setTab),
            const SizedBox(height: 20),
            if (_tab == _HelpTab.faqs)
              _FaqSection(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onSelectCategory: (c) => setState(() => _selectedCategory = _selectedCategory == c ? null : c),
                faqs: _filteredFaqs,
                onToggleStatus: _toggleFaqStatus,
                onDelete: _deleteFaq,
              )
            else if (_tab == _HelpTab.tickets)
              _TicketsSection(tickets: _filteredTickets, onStatusChange: _setTicketStatus)
            else
              _CategoriesSection(
                categories: _categories,
                faqCountFor: _faqCountFor,
                ticketCountFor: _ticketCountFor,
              ),
          ],
        ),
      ),
    );
  }
}

class _TabPills extends StatelessWidget {
  final _HelpTab selected;
  final ValueChanged<_HelpTab> onSelect;
  const _TabPills({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    Widget pill(_HelpTab tab, String label) {
      final isSelected = tab == selected;
      return GestureDetector(
        onTap: () => onSelect(tab),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.chipBlack : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill(_HelpTab.faqs, 'FAQs'),
        pill(_HelpTab.tickets, 'Support Tickets'),
        pill(_HelpTab.categories, 'Categories'),
      ],
    );
  }
}

class _FaqSection extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String> onSelectCategory;
  final List<FaqItem> faqs;
  final void Function(FaqItem) onToggleStatus;
  final void Function(FaqItem) onDelete;

  const _FaqSection({
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.faqs,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final categoryList = _CategoryPanel(
          categories: categories,
          selected: selectedCategory,
          onSelect: onSelectCategory,
        );
        final table = _FaqTable(faqs: faqs, onToggleStatus: onToggleStatus, onDelete: onDelete);

        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 220, child: categoryList),
              const SizedBox(width: 16),
              Expanded(child: table),
            ],
          );
        }
        return Column(children: [categoryList, const SizedBox(height: 16), table]);
      },
    );
  }
}

class _CategoryPanel extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _CategoryPanel({required this.categories, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('All Categories', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 4),
          for (final c in categories)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(c),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: c == selected ? AppColors.activeNavBackground : Colors.transparent,
                    border: c == selected ? const Border(left: BorderSide(color: AppColors.primary, width: 3)) : null,
                  ),
                  child: Text(
                    c,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: c == selected ? FontWeight.w700 : FontWeight.w500,
                      color: c == selected ? AppColors.primaryDark : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FaqTable extends StatelessWidget {
  final List<FaqItem> faqs;
  final void Function(FaqItem) onToggleStatus;
  final void Function(FaqItem) onDelete;

  const _FaqTable({required this.faqs, required this.onToggleStatus, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ScrollableTable(
        minWidth: 680,
        header: Row(
          children: const [
            AppTableHeaderCell(label: 'Question', width: 260),
            AppTableHeaderCell(label: 'Category', width: 180),
            AppTableHeaderCell(label: 'Status', width: 110),
            AppTableHeaderCell(label: 'Actions', width: 100),
          ],
        ),
        rows: [
          for (final faq in faqs)
            Row(
              children: [
                AppTableCell(width: 260, child: Text(faq.question, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis, maxLines: 2)),
                AppTableCell(width: 180, child: Text(faq.category, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                AppTableCell(width: 110, child: StatusBadge(status: faq.status)),
                AppTableCell(
                  width: 100,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                        onPressed: () => onToggleStatus(faq),
                        tooltip: faq.status == 'Published' ? 'Unpublish' : 'Publish',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textSecondary),
                        onPressed: () => onDelete(faq),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (faqs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No FAQs match your filters.', style: TextStyle(color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }
}

class _TicketsSection extends StatelessWidget {
  final List<SupportTicket> tickets;
  final void Function(SupportTicket, String) onStatusChange;

  const _TicketsSection({required this.tickets, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ScrollableTable(
        minWidth: 1150,
        header: Row(
          children: const [
            AppTableHeaderCell(label: 'Ticket ID', width: 140),
            AppTableHeaderCell(label: 'User/Customer', width: 130),
            AppTableHeaderCell(label: 'Subject', width: 220),
            AppTableHeaderCell(label: 'Category', width: 160),
            AppTableHeaderCell(label: 'Priority', width: 100),
            AppTableHeaderCell(label: 'Status', width: 110),
            AppTableHeaderCell(label: 'Last Update', width: 140),
            AppTableHeaderCell(label: 'Actions', width: 100),
          ],
        ),
        rows: [
          for (final t in tickets)
            Row(
              children: [
                AppTableCell(width: 140, child: Text(t.ticketId, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                AppTableCell(width: 130, child: Text(t.customer, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                AppTableCell(width: 220, child: Text(t.subject, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                AppTableCell(width: 160, child: Text(t.category, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                AppTableCell(width: 100, child: StatusBadge(status: t.priority)),
                AppTableCell(width: 110, child: StatusBadge(status: t.status)),
                AppTableCell(width: 140, child: Text(t.lastUpdated, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary))),
                AppTableCell(
                  width: 100,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit ${t.ticketId}'))),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 16, color: AppColors.textSecondary),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        itemBuilder: (context) => [
                          if (t.status != 'Open') const PopupMenuItem(value: 'Open', child: Text('Reopen')),
                          if (t.status != 'In Progress') const PopupMenuItem(value: 'In Progress', child: Text('Mark In Progress')),
                          if (t.status != 'Closed') const PopupMenuItem(value: 'Closed', child: Text('Close ticket')),
                        ],
                        onSelected: (value) => onStatusChange(t, value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (tickets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No tickets match your search.', style: TextStyle(color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  final List<String> categories;
  final int Function(String) faqCountFor;
  final int Function(String) ticketCountFor;

  const _CategoriesSection({
    required this.categories,
    required this.faqCountFor,
    required this.ticketCountFor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in categories) ...[
            _CategoryRow(name: c, faqCount: faqCountFor(c), ticketCount: ticketCountFor(c)),
            const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final int faqCount;
  final int ticketCount;

  const _CategoryRow({required this.name, required this.faqCount, required this.ticketCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
        Text('$faqCount FAQs', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(width: 20),
        Text('$ticketCount tickets', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(width: 20),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit $name'))),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
