import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../features/partnerships/domain/entities/compliance.dart';
import '../../features/partnerships/domain/usecases/partnership_usecases.dart';
import '../../theme/app_colors.dart';
import '../common/status_badge.dart';
import '../common/table_cell.dart';
import 'partnership_formatting.dart';

/// Runs `GET /partnerships/compliance/report` over a chosen month range.
///
/// Kept out of Redux: the report is a one-off query with its own inputs,
/// nothing else in the app reads it, and caching it in the store would mean
/// carrying a date range around in global state for one panel.
class ComplianceReportPanel extends StatefulWidget {
  const ComplianceReportPanel({super.key});

  @override
  State<ComplianceReportPanel> createState() => _ComplianceReportPanelState();
}

class _ComplianceReportPanelState extends State<ComplianceReportPanel> {
  late DateTime _start = DateTime(DateTime.now().year, DateTime.now().month - 5);
  late DateTime _end = DateTime(DateTime.now().year, DateTime.now().month);

  Future<List<ComplianceReportRow>>? _report;

  Future<void> _pick({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: isStart ? 'Report starts' : 'Report ends',
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _start = picked;
        if (_end.isBefore(picked)) _end = picked;
      } else {
        _end = picked;
        if (_start.isAfter(picked)) _start = picked;
      }
    });
  }

  void _run() {
    setState(() {
      _report = sl<GetComplianceReportUseCase>().call(
        ComplianceReportParams(startDate: _start, endDate: _end),
      );
    });
  }

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
          const Text(
            'Compliance report',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'Monthly compliance per agreement over a date range',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _RangeButton(
                label: 'From',
                value: formatMonth(_start),
                onTap: () => _pick(isStart: true),
              ),
              _RangeButton(
                label: 'To',
                value: formatMonth(_end),
                onTap: () => _pick(isStart: false),
              ),
              FilledButton(
                onPressed: _run,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Run report',
                    style: TextStyle(fontSize: 12.5)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_report == null)
            const Text(
              'Pick a range and run the report.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            )
          else
            FutureBuilder<List<ComplianceReportRow>>(
              future: _report,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    '${snapshot.error}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.danger),
                  );
                }

                final rows = snapshot.data ?? const <ComplianceReportRow>[];
                if (rows.isEmpty) {
                  return const Text(
                    'No compliance was recorded in that range.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  );
                }

                return ScrollableTable(
                  minWidth: 860,
                  header: const Row(
                    children: [
                      AppTableHeaderCell(label: 'Counterparty', width: 220),
                      AppTableHeaderCell(label: 'Month', width: 110),
                      AppTableHeaderCell(label: 'Claims', width: 110),
                      AppTableHeaderCell(label: 'On time', width: 150),
                      AppTableHeaderCell(label: 'Score', width: 100),
                      AppTableHeaderCell(label: 'Agreement', width: 110),
                    ],
                  ),
                  rows: [
                    for (final row in rows)
                      Row(
                        children: [
                          AppTableCell(
                            width: 220,
                            child: Text(
                              row.entityName ??
                                  '${titleCase(row.entityType)} '
                                      '#${row.agreementId}',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppTableCell(
                            width: 110,
                            child: Text(
                              formatMonth(row.monthDate),
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          AppTableCell(
                            width: 110,
                            child: Text(
                              '${row.claimsAccepted}/${row.totalClaims}',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          AppTableCell(
                            width: 150,
                            child: Text(
                              '${row.onTimeResponses} responses · '
                              '${row.onTimeDispensed} dispensed',
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          AppTableCell(
                            width: 100,
                            child: Text(
                              formatPercent(row.complianceScore),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          AppTableCell(
                            width: 110,
                            child: StatusBadge(status: titleCase(row.status)),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RangeButton extends StatelessWidget {
  const _RangeButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label ',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
