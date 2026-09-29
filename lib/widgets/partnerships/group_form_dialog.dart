import 'package:flutter/material.dart';

import '../../features/partnerships/domain/entities/pharmacy_group.dart';
import '../../features/partnerships/domain/usecases/partnership_usecases.dart';
import '../../theme/app_colors.dart';

/// Creates or edits a pharmacy group.
///
/// Returns [CreateGroupParams] on save and null on cancel. The caller decides
/// whether that becomes a create or an update — the field set is identical,
/// and the edit path simply carries the group id alongside.
class GroupFormDialog extends StatefulWidget {
  const GroupFormDialog({super.key, this.existing});

  /// Pre-fills the form when editing.
  final PharmacyGroup? existing;

  @override
  State<GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<GroupFormDialog> {
  /// The server validates against exactly this set and rejects anything else
  /// with a 400 — including null, which is why the field has no empty option.
  static const _tiers = ['premium', 'standard', 'basic'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.groupName ?? '');
  late final TextEditingController _parent =
      TextEditingController(text: widget.existing?.parentCompany ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late final TextEditingController _commission = TextEditingController(
    text: widget.existing?.commissionRate?.toString() ?? '',
  );

  late String _tier = widget.existing?.tier ?? 'standard';

  @override
  void dispose() {
    _name.dispose();
    _parent.dispose();
    _description.dispose();
    _commission.dispose();
    super.dispose();
  }

  String? _validateCommission(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final rate = double.tryParse(text);
    if (rate == null) return 'Enter a number, e.g. 12.5';
    // The column is DECIMAL(5,2) holding a percentage, so anything at or
    // above 1000 overflows and anything negative is meaningless.
    if (rate < 0 || rate > 100) return 'Enter a percentage between 0 and 100';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    String? optional(TextEditingController controller) {
      final text = controller.text.trim();
      return text.isEmpty ? null : text;
    }

    Navigator.of(context).pop(CreateGroupParams(
      groupName: _name.text.trim(),
      tier: _tier,
      parentCompany: optional(_parent),
      description: optional(_description),
      commissionRate: double.tryParse(_commission.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        isEditing ? 'Edit group' : 'New pharmacy group',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Group name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'A group name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _tier,
                  decoration: const InputDecoration(
                    labelText: 'Tier',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final tier in _tiers)
                      DropdownMenuItem(
                        value: tier,
                        child: Text(
                          tier[0].toUpperCase() + tier.substring(1),
                        ),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _tier = value ?? _tier),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _parent,
                  decoration: const InputDecoration(
                    labelText: 'Parent company (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _commission,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Commission rate %',
                    hintText: 'e.g. 12.5',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateCommission,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
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
          child: Text(isEditing ? 'Save changes' : 'Create group'),
        ),
      ],
    );
  }
}
