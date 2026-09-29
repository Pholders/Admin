import 'package:flutter/material.dart';

import '../../features/partnerships/domain/entities/pharmacy_group.dart';
import '../../features/partnerships/domain/usecases/partnership_usecases.dart';
import '../../theme/app_colors.dart';
import 'partnership_formatting.dart';

/// Creates a partnership agreement with either a group or a single pharmacy.
///
/// Returns [CreateAgreementParams] on save, null on cancel. New agreements
/// always land in `pending` — the server sets that default and only the
/// activate route moves them on, so there is no status field here.
class AgreementFormDialog extends StatefulWidget {
  const AgreementFormDialog({
    super.key,
    required this.groups,
    required this.pharmacies,
  });

  final List<PharmacyGroup> groups;
  final List<PharmacyDirectoryEntry> pharmacies;

  @override
  State<AgreementFormDialog> createState() => _AgreementFormDialogState();
}

class _AgreementFormDialogState extends State<AgreementFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _commission = TextEditingController();
  final _serviceFee = TextEditingController();
  final _minimumTransactions = TextEditingController();
  // The server's own column defaults, shown up front so the SLA is a
  // deliberate choice rather than a silent one.
  final _responseHours = TextEditingController(text: '24');
  final _dispensingHours = TextEditingController(text: '48');
  final _agreementType = TextEditingController();
  final _paymentTerms = TextEditingController();

  String _entityType = 'group';
  int? _entityId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _autoRenew = false;

  @override
  void dispose() {
    _commission.dispose();
    _serviceFee.dispose();
    _minimumTransactions.dispose();
    _responseHours.dispose();
    _dispensingHours.dispose();
    _agreementType.dispose();
    _paymentTerms.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<int>> get _entityOptions {
    if (_entityType == 'group') {
      return [
        for (final group in widget.groups)
          DropdownMenuItem(
            value: group.id,
            child: Text('${group.groupName} · ${titleCase(group.tier)}'),
          ),
      ];
    }
    return [
      for (final entry in widget.pharmacies)
        DropdownMenuItem(
          value: entry.id,
          child: Text(entry.pharmacy.pharmacyName),
        ),
    ];
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : (_endDate ?? _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        // An end date that now precedes the start would be rejected by the
        // SLA checks downstream; drop it rather than submit an invalid span.
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  String? _validatePercent(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'A commission rate is required';
    final rate = double.tryParse(text);
    if (rate == null) return 'Enter a number, e.g. 12.5';
    if (rate < 0 || rate > 100) return 'Enter a percentage between 0 and 100';
    return null;
  }

  String? _validateHours(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final hours = int.tryParse(text);
    if (hours == null || hours <= 0) return 'Enter a whole number of hours';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_entityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose who the agreement is with.')),
      );
      return;
    }

    String? optionalText(TextEditingController controller) {
      final text = controller.text.trim();
      return text.isEmpty ? null : text;
    }

    Navigator.of(context).pop(CreateAgreementParams(
      pharmacyOrGroupId: _entityId!,
      entityType: _entityType,
      commissionRate: double.parse(_commission.text.trim()),
      agreementType: optionalText(_agreementType),
      startDate: _startDate,
      endDate: _endDate,
      autoRenew: _autoRenew,
      serviceFee: double.tryParse(_serviceFee.text.trim()),
      minimumMonthlyTransactions:
          int.tryParse(_minimumTransactions.text.trim()),
      claimResponseTimeHours: int.tryParse(_responseHours.text.trim()),
      dispensingTimeHours: int.tryParse(_dispensingHours.text.trim()),
      paymentTerms: optionalText(_paymentTerms),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('New partnership agreement',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'group', label: Text('With a group')),
                    ButtonSegment(
                        value: 'pharmacy', label: Text('With one pharmacy')),
                  ],
                  selected: {_entityType},
                  onSelectionChanged: (selection) => setState(() {
                    _entityType = selection.first;
                    // The two lists index different tables, so a carried-over
                    // id would silently point at the wrong record.
                    _entityId = null;
                  }),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _entityId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText:
                        _entityType == 'group' ? 'Group' : 'Pharmacy',
                    border: const OutlineInputBorder(),
                  ),
                  items: _entityOptions,
                  onChanged: (value) => setState(() => _entityId = value),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _commission,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Commission rate %',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validatePercent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _serviceFee,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Service fee (R)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _responseHours,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Claim response (hours)',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateHours,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _dispensingHours,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Dispensing (hours)',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateHours,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Start date',
                        value: _startDate,
                        onTap: () => _pickDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'End date (optional)',
                        value: _endDate,
                        onTap: () => _pickDate(isStart: false),
                        onClear: _endDate == null
                            ? null
                            : () => setState(() => _endDate = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _agreementType,
                        decoration: const InputDecoration(
                          labelText: 'Agreement type',
                          hintText: 'e.g. standard, exclusive',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _paymentTerms,
                        decoration: const InputDecoration(
                          labelText: 'Payment terms',
                          hintText: 'e.g. net 30',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _minimumTransactions,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimum monthly transactions (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _autoRenew,
                  onChanged: (value) =>
                      setState(() => _autoRenew = value ?? false),
                  title: const Text('Auto-renew for a year on expiry',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDark),
          onPressed: _submit,
          child: const Text('Create agreement'),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: onClear == null
              ? const Icon(Icons.calendar_today_outlined, size: 16)
              : IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: onClear,
                ),
        ),
        child: Text(
          value == null ? 'Not set' : formatDay(value),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}
