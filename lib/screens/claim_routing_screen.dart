import 'package:flutter/material.dart';

import 'package:pholders_admin/store.dart';
import '../theme/app_colors.dart';
import '../widgets/admin/admin_format.dart';
import '../widgets/admin/admin_ui.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/shell/app_shell.dart';

/// How prescription claims are routed to partner pharmacies: overall
/// statistics, results by tier, and the candidates for a location.
class ClaimRoutingScreen extends StatelessWidget {
  const ClaimRoutingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPage: 'Claim Routing',
      body: PinnedPage(
          sections: true,
          header: [
            ScreenTitle(
              title: 'Claim Routing',
              subtitle: 'Which pharmacies prescriptions are routed to, and how they respond',
              actions: [
                SecondaryButton(
                  label: 'Refresh',
                  icon: Icons.refresh,
                  onPressed: () {
                    reloadAdmin(context, AdminResource.routingStatistics);
                    reloadAdmin(context, AdminResource.routingByTier);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          body: (_) => const Column(children: [
            _Statistics(),
            SizedBox(height: 18),
            _ByTier(),
            SizedBox(height: 18),
            _Candidates(),
          ]),
      ),
    );
  }
}

String _seconds(dynamic value) {
  final s = numOf(value);
  if (s == null) return '—';
  if (s < 60) return '${formatNumber(s, decimals: 0)}s';
  if (s < 3600) return '${formatNumber(s / 60, decimals: 1)} min';
  return '${formatNumber(s / 3600, decimals: 1)} h';
}

class _Statistics extends StatefulWidget {
  const _Statistics();

  @override
  State<_Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<_Statistics> {
  DateTime? _start;
  DateTime? _end;

  Map<String, dynamic> get _params => {
        if (_start != null) 'start_date': apiDate(_start!),
        if (_end != null) 'end_date': apiDate(_end!),
      };

  void _apply() => loadAdmin(context, AdminResource.routingStatistics, params: _params);

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Routing Statistics',
      subtitle: 'All time unless a date range is set',
      trailing: Wrap(spacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(
          width: 170,
          child: AdminDateInput(
              value: _start,
              hint: 'From',
              clearable: true,
              onChanged: (d) {
                setState(() => _start = d);
                _apply();
              }),
        ),
        SizedBox(
          width: 170,
          child: AdminDateInput(
              value: _end,
              hint: 'To',
              clearable: true,
              onChanged: (d) {
                setState(() => _end = d);
                _apply();
              }),
        ),
      ]),
      child: AdminResourceBuilder(
        resource: AdminResource.routingStatistics,
        load: _params,
        builder: (context, data) => AsyncContent(
          data: data,
          onRetry: () => reloadAdmin(context, AdminResource.routingStatistics),
          builder: (raw) {
            final s = mapOf(raw);
            final total = numOf(s['total_routes']) ?? 0;
            final accepted = numOf(s['accepted_count']) ?? 0;
            return Column(children: [
              StatGrid(stats: [
                StatCardData(label: 'Claims Routed', value: formatNumber(total), icon: Icons.alt_route),
                StatCardData(
                    label: 'Accepted',
                    value: total == 0 ? '0' : '${formatNumber(accepted)} (${percent(accepted / total * 100)})',
                    icon: Icons.check_circle_outline),
                StatCardData(
                    label: 'Awaiting Response',
                    value: formatValue(numOf(s['pending_count']) ?? 0),
                    icon: Icons.hourglass_empty),
                StatCardData(
                    label: 'Rejected', value: formatValue(numOf(s['rejected_count']) ?? 0), icon: Icons.block_outlined),
              ]),
              const SizedBox(height: 14),
              StatGrid(perRow: 3, stats: [
                StatCardData(label: 'Avg Response', value: _seconds(s['avg_response_time']), icon: Icons.timer_outlined),
                StatCardData(label: 'Fastest', value: _seconds(s['min_response_time']), icon: Icons.bolt_outlined),
                StatCardData(label: 'Slowest', value: _seconds(s['max_response_time']), icon: Icons.snooze_outlined),
              ]),
            ]);
          },
        ),
      ),
    );
  }
}

class _ByTier extends StatelessWidget {
  const _ByTier();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Results by Tier',
      subtitle: 'Acceptance of routed claims by the receiving pharmacy\'s group tier',
      child: AdminResourceBuilder(
        resource: AdminResource.routingByTier,
        load: const {},
        builder: (context, data) => AsyncContent(
          data: data,
          onRetry: () => reloadAdmin(context, AdminResource.routingByTier),
          builder: (raw) => RecordTable(
            rows: recordsOf(raw),
            emptyMessage: 'No claims have been routed to grouped pharmacies yet.',
            columns: [
              RecordColumn('Tier',
                  width: 140,
                  cell: (r) => Align(
                      alignment: Alignment.centerLeft,
                      child: StatusBadge(status: humanize('${r['tier'] ?? '—'}')))),
              const RecordColumn('Routed', field: 'total_routes', width: 110),
              const RecordColumn('Accepted', field: 'accepted', width: 110),
              const RecordColumn('Rejected', field: 'rejected', width: 110),
              RecordColumn('Acceptance Rate', width: 280, cell: (r) => _RateBar(rate: numOf(r['acceptance_rate']))),
            ],
          ),
        ),
      ),
    );
  }
}

class _RateBar extends StatelessWidget {
  final num? rate;
  const _RateBar({required this.rate});

  @override
  Widget build(BuildContext context) {
    final value = ((rate ?? 0) / 100).clamp(0.0, 1.0).toDouble();
    return Row(children: [
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            color: AppColors.primary,
            backgroundColor: AppColors.chartTealPale,
          ),
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(width: 44, child: CellText(percent(rate), strong: true)),
    ]);
  }
}

class _Candidates extends StatefulWidget {
  const _Candidates();

  @override
  State<_Candidates> createState() => _CandidatesState();
}

class _CandidatesState extends State<_Candidates> {
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  void _find() {
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    if (lat == null || lat < -90 || lat > 90 || lng == null || lng < -180 || lng > 180) {
      setState(() => _error = 'Enter a latitude (−90 to 90) and longitude (−180 to 180).');
      return;
    }
    setState(() => _error = null);
    loadAdmin(context, AdminResource.routingCandidates,
        params: {'latitude': lat, 'longitude': lng}, force: true);
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Routing Candidates',
      subtitle: 'The pharmacies a claim from this location would be offered to, in order',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: 180,
                child: LabeledField(
                  label: 'Latitude',
                  child: AdminTextInput(
                      controller: _lat,
                      hint: '-26.2041',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      onSubmitted: (_) => _find()),
                ),
              ),
              SizedBox(
                width: 180,
                child: LabeledField(
                  label: 'Longitude',
                  child: AdminTextInput(
                      controller: _lng,
                      hint: '28.0473',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      onSubmitted: (_) => _find()),
                ),
              ),
              PrimaryButton(label: 'Find Candidates', icon: Icons.search, onPressed: _find),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorPanel(message: _error!, compact: true),
          ],
          const SizedBox(height: 16),
          AdminResourceBuilder(
            resource: AdminResource.routingCandidates,
            builder: (context, data) => AsyncContent(
              data: data,
              idleMessage: 'Enter coordinates to see which pharmacies would be offered a claim.',
              onRetry: () => reloadAdmin(context, AdminResource.routingCandidates),
              builder: (raw) => RecordTable(
                rows: recordsOf(raw),
                maxAutoColumns: 9,
                emptyMessage: 'No partner pharmacies with an active agreement.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
