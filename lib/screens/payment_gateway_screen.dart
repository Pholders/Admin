import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/shell/app_shell.dart';

class PaymentGatewayScreen extends StatefulWidget {
  const PaymentGatewayScreen({super.key});

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  static const _gatewayNames = ['PayFast', 'PayFlex', 'Stripe'];
  static const _otherCategories = ['Orders & Prescriptions', 'Account & Security', 'General'];

  final Map<String, bool> _enabled = {
    'PayFast': true,
    'Orders & Prescriptions': true,
    'PayFlex': false,
    'Stripe': false,
  };

  static const Map<String, String> _descriptions = {
    'PayFast': 'Accept payments securely through PayFast',
    'PayFlex': 'Offer buy-now-pay-later installments via PayFlex',
    'Stripe': 'Accept cards and digital wallets through Stripe',
  };

  String _selected = 'PayFast';

  final Map<String, Map<String, TextEditingController>> _fieldControllers = {
    for (final gateway in _gatewayNames)
      gateway: {
        'Merchant ID': TextEditingController(),
        'Merchant Key': TextEditingController(),
        'Passphrase': TextEditingController(),
        'Webhook URL': TextEditingController(),
      },
  };

  bool _testing = false;
  bool? _connectionSuccess;

  @override
  void dispose() {
    for (final map in _fieldControllers.values) {
      for (final c in map.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _toggleEnabled(String name) {
    setState(() => _enabled[name] = !(_enabled[name] ?? false));
  }

  void _select(String name) {
    setState(() {
      _selected = name;
      _connectionSuccess = null;
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _connectionSuccess = null;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _testing = false;
      _connectionSuccess = true;
    });
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment gateway settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: 'Payment Gateway',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Gateway', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    const Text('Configure and manage payment gateways', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                final categoryList = _CategoryList(
                  gatewayNames: _gatewayNames,
                  otherCategories: _otherCategories,
                  enabled: _enabled,
                  selected: _selected,
                  onSelect: _select,
                  onToggle: _toggleEnabled,
                );
                final detail = _selected == 'PayFast' || _selected == 'PayFlex' || _selected == 'Stripe'
                    ? _GatewayForm(
                        name: _selected,
                        description: _descriptions[_selected] ?? '',
                        controllers: _fieldControllers[_selected]!,
                        testing: _testing,
                        connectionSuccess: _connectionSuccess,
                        onTestConnection: _testConnection,
                      )
                    : _CategoryPlaceholder(name: _selected);

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 260, child: categoryList),
                      const SizedBox(width: 20),
                      Expanded(child: detail),
                    ],
                  );
                }
                return Column(children: [categoryList, const SizedBox(height: 20), detail]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<String> gatewayNames;
  final List<String> otherCategories;
  final Map<String, bool> enabled;
  final String selected;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onToggle;

  const _CategoryList({
    required this.gatewayNames,
    required this.otherCategories,
    required this.enabled,
    required this.selected,
    required this.onSelect,
    required this.onToggle,
  });

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: const Text('All Categories', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 4),
          for (final name in gatewayNames)
            _CategoryTile(
              name: name,
              statusLabel: enabled[name] == true ? 'Enabled' : 'Disabled',
              selected: name == selected,
              onTap: () => onSelect(name),
              onToggle: () => onToggle(name),
            ),
          const Divider(height: 20),
          for (final name in otherCategories)
            _CategoryTile(
              name: name,
              statusLabel: enabled.containsKey(name) ? (enabled[name] == true ? 'Enabled' : 'Disabled') : null,
              selected: name == selected,
              onTap: () => onSelect(name),
              onToggle: enabled.containsKey(name) ? () => onToggle(name) : null,
            ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String name;
  final String? statusLabel;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onToggle;

  const _CategoryTile({
    required this.name,
    required this.statusLabel,
    required this.selected,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.activeNavBackground : Colors.transparent,
            border: selected ? const Border(left: BorderSide(color: AppColors.primary, width: 3)) : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                  ),
                ),
              ),
              if (statusLabel != null)
                GestureDetector(
                  onTap: onToggle,
                  child: Text(
                    statusLabel!,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: statusLabel == 'Enabled' ? const Color(0xFF1FA97C) : AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GatewayForm extends StatelessWidget {
  final String name;
  final String description;
  final Map<String, TextEditingController> controllers;
  final bool testing;
  final bool? connectionSuccess;
  final VoidCallback onTestConnection;

  const _GatewayForm({
    required this.name,
    required this.description,
    required this.controllers,
    required this.testing,
    required this.connectionSuccess,
    required this.onTestConnection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          for (final entry in controllers.entries) ...[
            _FieldRow(
              label: entry.key,
              controller: entry.value,
              obscure: entry.key == 'Merchant Key' || entry.key == 'Passphrase',
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: testing ? null : onTestConnection,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                child: testing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Text('Test Connection', style: TextStyle(fontSize: 12.5)),
              ),
              const SizedBox(width: 14),
              if (connectionSuccess == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1FA97C).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Connection Successful',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF1FA97C), fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;

  const _FieldRow({required this.label, required this.controller, required this.obscure});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.contentBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Enter $label',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryPlaceholder extends StatelessWidget {
  final String name;
  const _CategoryPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction_outlined, size: 36, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text('$name settings coming soon', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
