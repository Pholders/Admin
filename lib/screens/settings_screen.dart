import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/shell/app_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _tabs = [
    'General Settings',
    'User Management',
    'Notifications',
    'Security',
    'Prescriptions',
    'Orders & Returns',
    'Financial',
    'System Logs',
  ];

  String _selectedTab = 'General Settings';

  // General settings form state
  final _systemNameController = TextEditingController(text: 'MedCare Admin');
  final _systemEmailController = TextEditingController(text: 'support@medcare.co.za');
  String _timeZone = 'UTC+02:00 Johannesburg';
  String _dateFormat = 'DD/MM/YYYY';
  String _currency = 'ZAR R - South African Rand';
  String _language = 'English';
  String _itemsPerPage = '10';

  static const List<Color> _colorOptions = [
    AppColors.primary,
    Color(0xFF2F80ED),
    Color(0xFF7C6FEA),
    Color(0xFFE0577B),
    Color(0xFF1FA97C),
    Color(0xFF1F2B34),
  ];
  int _primaryColorIndex = 0;
  int _sidebarColorIndex = 5;

  @override
  void dispose() {
    _systemNameController.dispose();
    _systemEmailController.dispose();
    super.dispose();
  }

  void _cycleColor(bool primary) {
    setState(() {
      if (primary) {
        _primaryColorIndex = (_primaryColorIndex + 1) % _colorOptions.length;
      } else {
        _sidebarColorIndex = (_sidebarColorIndex + 1) % _colorOptions.length;
      }
    });
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: 'Settings',
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubNav(
                tabs: _tabs,
                selected: _selectedTab,
                onSelect: (t) => setState(() => _selectedTab = t),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: _selectedTab == 'General Settings'
                      ? _GeneralSettingsPanel(
                          systemNameController: _systemNameController,
                          systemEmailController: _systemEmailController,
                          timeZone: _timeZone,
                          dateFormat: _dateFormat,
                          currency: _currency,
                          language: _language,
                          itemsPerPage: _itemsPerPage,
                          onTimeZoneChanged: (v) => setState(() => _timeZone = v!),
                          onDateFormatChanged: (v) => setState(() => _dateFormat = v!),
                          onCurrencyChanged: (v) => setState(() => _currency = v!),
                          onLanguageChanged: (v) => setState(() => _language = v!),
                          onItemsPerPageChanged: (v) => setState(() => _itemsPerPage = v!),
                          primaryColor: _colorOptions[_primaryColorIndex],
                          sidebarColor: _colorOptions[_sidebarColorIndex],
                          onChangeLogo: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Logo upload isn\'t wired to a backend in this demo yet')),
                          ),
                          onPrimaryColorTap: () => _cycleColor(true),
                          onSidebarColorTap: () => _cycleColor(false),
                          onSave: _save,
                        )
                      : _PlaceholderPanel(title: _selectedTab),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SubNav extends StatelessWidget {
  final List<String> tabs;
  final String selected;
  final ValueChanged<String> onSelect;

  const _SubNav({required this.tabs, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (final tab in tabs)
            _SubNavItem(label: tab, selected: tab == selected, onTap: () => onSelect(tab)),
        ],
      ),
    );
  }
}

class _SubNavItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SubNavItem({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.activeNavBackground : Colors.transparent,
            border: selected ? const Border(left: BorderSide(color: AppColors.primary, width: 3)) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? AppColors.primaryDark : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderPanel extends StatelessWidget {
  final String title;
  const _PlaceholderPanel({required this.title});

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
          Text('$title settings coming soon', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _GeneralSettingsPanel extends StatelessWidget {
  final TextEditingController systemNameController;
  final TextEditingController systemEmailController;
  final String timeZone;
  final String dateFormat;
  final String currency;
  final String language;
  final String itemsPerPage;
  final ValueChanged<String?> onTimeZoneChanged;
  final ValueChanged<String?> onDateFormatChanged;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<String?> onItemsPerPageChanged;
  final Color primaryColor;
  final Color sidebarColor;
  final VoidCallback onChangeLogo;
  final VoidCallback onPrimaryColorTap;
  final VoidCallback onSidebarColorTap;
  final VoidCallback onSave;

  const _GeneralSettingsPanel({
    required this.systemNameController,
    required this.systemEmailController,
    required this.timeZone,
    required this.dateFormat,
    required this.currency,
    required this.language,
    required this.itemsPerPage,
    required this.onTimeZoneChanged,
    required this.onDateFormatChanged,
    required this.onCurrencyChanged,
    required this.onLanguageChanged,
    required this.onItemsPerPageChanged,
    required this.primaryColor,
    required this.sidebarColor,
    required this.onChangeLogo,
    required this.onPrimaryColorTap,
    required this.onSidebarColorTap,
    required this.onSave,
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
          const Text('General Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final formFields = _FormFields(
                systemNameController: systemNameController,
                systemEmailController: systemEmailController,
                timeZone: timeZone,
                dateFormat: dateFormat,
                currency: currency,
                language: language,
                itemsPerPage: itemsPerPage,
                onTimeZoneChanged: onTimeZoneChanged,
                onDateFormatChanged: onDateFormatChanged,
                onCurrencyChanged: onCurrencyChanged,
                onLanguageChanged: onLanguageChanged,
                onItemsPerPageChanged: onItemsPerPageChanged,
              );
              final branding = _BrandingPanel(
                primaryColor: primaryColor,
                sidebarColor: sidebarColor,
                onChangeLogo: onChangeLogo,
                onPrimaryColorTap: onPrimaryColorTap,
                onSidebarColorTap: onSidebarColorTap,
              );
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: formFields),
                    const SizedBox(width: 32),
                    Expanded(flex: 1, child: branding),
                  ],
                );
              }
              return Column(children: [formFields, const SizedBox(height: 24), branding]);
            },
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormFields extends StatelessWidget {
  final TextEditingController systemNameController;
  final TextEditingController systemEmailController;
  final String timeZone;
  final String dateFormat;
  final String currency;
  final String language;
  final String itemsPerPage;
  final ValueChanged<String?> onTimeZoneChanged;
  final ValueChanged<String?> onDateFormatChanged;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<String?> onItemsPerPageChanged;

  const _FormFields({
    required this.systemNameController,
    required this.systemEmailController,
    required this.timeZone,
    required this.dateFormat,
    required this.currency,
    required this.language,
    required this.itemsPerPage,
    required this.onTimeZoneChanged,
    required this.onDateFormatChanged,
    required this.onCurrencyChanged,
    required this.onLanguageChanged,
    required this.onItemsPerPageChanged,
  });

  static const _timeZones = ['UTC+02:00 Johannesburg', 'UTC+00:00 London', 'UTC-05:00 New York', 'UTC+01:00 Lagos'];
  static const _dateFormats = ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'];
  static const _currencies = ['ZAR R - South African Rand', 'USD \$ - US Dollar', 'EUR € - Euro', 'GBP £ - British Pound'];
  static const _languages = ['English', 'Afrikaans', 'Zulu', 'French'];
  static const _pageSizes = ['10', '25', '50', '100'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _LabeledField(label: 'System Name', child: _TextInput(controller: systemNameController))),
            const SizedBox(width: 16),
            Expanded(child: _LabeledField(label: 'System Email', child: _TextInput(controller: systemEmailController))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _LabeledField(label: 'Time Zone', child: _Dropdown(value: timeZone, items: _timeZones, onChanged: onTimeZoneChanged))),
            const SizedBox(width: 16),
            Expanded(child: _LabeledField(label: 'Date Format', child: _Dropdown(value: dateFormat, items: _dateFormats, onChanged: onDateFormatChanged))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _LabeledField(label: 'Currency', child: _Dropdown(value: currency, items: _currencies, onChanged: onCurrencyChanged))),
            const SizedBox(width: 16),
            Expanded(child: _LabeledField(label: 'Language', child: _Dropdown(value: language, items: _languages, onChanged: onLanguageChanged))),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 200,
          child: _LabeledField(label: 'Items Per Page', child: _Dropdown(value: itemsPerPage, items: _pageSizes, onChanged: onItemsPerPageChanged)),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  const _TextInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.contentBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        decoration: const InputDecoration(isDense: true, border: InputBorder.none),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.contentBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          items: [for (final item in items) DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis))],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _BrandingPanel extends StatelessWidget {
  final Color primaryColor;
  final Color sidebarColor;
  final VoidCallback onChangeLogo;
  final VoidCallback onPrimaryColorTap;
  final VoidCallback onSidebarColorTap;

  const _BrandingPanel({
    required this.primaryColor,
    required this.sidebarColor,
    required this.onChangeLogo,
    required this.onPrimaryColorTap,
    required this.onSidebarColorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Branding', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        const Text('Logo', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.contentBackground, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.image_outlined, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton(
                    onPressed: onChangeLogo,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Change Logo', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(height: 4),
                  const Text('Recommended 200x200px, PNG', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ColorField(label: 'Primary Color', color: primaryColor, onTap: onPrimaryColorTap),
        const SizedBox(height: 16),
        _ColorField(label: 'Sidebar Color', color: sidebarColor, onTap: onSidebarColorTap),
      ],
    );
  }
}

class _ColorField extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ColorField({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
          ),
        ),
      ],
    );
  }
}
