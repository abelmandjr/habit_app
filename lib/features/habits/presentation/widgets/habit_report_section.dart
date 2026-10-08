import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/habit_type.dart';
import '../../../../core/utils/habit_report_calculator.dart';
import '../../../../core/utils/date_utils.dart';
import 'streak_calendar.dart';
import 'streak_card.dart';
import '../../../../l10n/app_formats.dart';
import '../../../../l10n/app_localizations.dart';

class HabitReportSection extends StatelessWidget {
  const HabitReportSection({
    super.key,
    required this.type,
    required this.unit,
    required this.goalValue,
    required this.habitCreatedAt,
    this.yesNoReport,
    this.quantitativeReport,
    this.onDayTap,
  });

  final HabitType type;
  final String unit;
  final int goalValue;
  final DateTime habitCreatedAt;
  final YesNoHabitReport? yesNoReport;
  final QuantitativeHabitReport? quantitativeReport;
  final void Function(DateTime day)? onDayTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).reportTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (type == HabitType.yesNo && yesNoReport != null)
          _YesNoReportView(
            report: yesNoReport!,
            habitCreatedAt: habitCreatedAt,
            onDayTap: onDayTap,
          )
        else if (type == HabitType.quantitative &&
            quantitativeReport != null)
          _QuantitativeReportView(
            report: quantitativeReport!,
            unit: unit,
            goalValue: goalValue,
            habitCreatedAt: habitCreatedAt,
            onDayTap: onDayTap,
          ),
      ],
    );
  }
}

class _YesNoReportView extends StatelessWidget {
  const _YesNoReportView({
    required this.report,
    required this.habitCreatedAt,
    this.onDayTap,
  });

  final YesNoHabitReport report;
  final DateTime habitCreatedAt;
  final void Function(DateTime day)? onDayTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricsGrid(
          items: [
            _Metric(l10n.metricDaysDone, '${report.daysDone}'),
            _Metric(l10n.metricDaysMissed, '${report.daysFailed}'),
            _Metric(
              l10n.metricSuccess,
              AppFormats.percent(report.successRate / 100),
            ),
            _Metric(l10n.metricTrackedDays, '${report.trackedDays}'),
          ],
        ),
        const SizedBox(height: 20),
        StreakCard(streak: report.streak),
        const SizedBox(height: 20),
        StreakCalendar(
          completionDates: report.completionDates,
          loggedDates: report.completionDates,
          habitCreatedAt: habitCreatedAt,
          onDayTap: onDayTap,
        ),
        if (onDayTap != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.reportTapToEdit,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

class _QuantitativeReportView extends StatelessWidget {
  const _QuantitativeReportView({
    required this.report,
    required this.unit,
    required this.goalValue,
    required this.habitCreatedAt,
    this.onDayTap,
  });

  final QuantitativeHabitReport report;
  final String unit;
  final int goalValue;
  final DateTime habitCreatedAt;
  final void Function(DateTime day)? onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    String qty(num v) => AppFormats.quantity(v, unit);
    final bestLabel = report.bestDayDate != null
        ? '${qty(report.bestDayValue)} (${AppFormats.dayMonth(HabitDateUtils.parseKey(report.bestDayDate!))})'
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricsGrid(
          items: [
            _Metric(l10n.metricToday, qty(report.todayValue)),
            _Metric(l10n.metricDailyAverage, qty(report.dailyAverage)),
            _Metric(l10n.metricTotal, qty(report.totalAccumulated)),
            _Metric(l10n.metricBestDay, bestLabel),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reportGoalProgress,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: report.goalProgress,
                          minHeight: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppFormats.percent(report.goalProgress),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${AppFormats.number(report.todayValue)} / ${qty(goalValue)}'
                  '${report.goalMetToday ? '  ${l10n.reportGoalMet}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        StreakCard(streak: report.streak),
        const SizedBox(height: 20),
        StreakCalendar(
          completionDates: report.goalMetDates,
          loggedDates: report.loggedDates,
          habitCreatedAt: habitCreatedAt,
          onDayTap: onDayTap,
        ),
        if (onDayTap != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.reportTapToEditValues,
            style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          l10n.reportEvolution,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: _EvolutionChart(
            history: report.history,
            goal: goalValue.toDouble(),
            unit: unit,
          ),
        ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.items});

  final List<_Metric> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (m) => SizedBox(
                  width: width,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.label,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            m.value,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
}

class _EvolutionChart extends StatelessWidget {
  const _EvolutionChart({
    required this.history,
    required this.goal,
    required this.unit,
  });

  final List<QuantitativeDayValue> history;
  final double goal;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxVal = history.fold<double>(
      goal,
      (m, e) => e.value > m ? e.value : m,
    );
    final chartMax = (maxVal * 1.2).clamp(goal, double.infinity);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: chartMax <= 0 ? 1 : chartMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartMax / 4,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= history.length || i % 5 != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    AppFormats.dayMonth(HabitDateUtils.parseKey(history[i].date)),
                    style: theme.textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: goal,
              color: theme.colorScheme.secondary.withValues(alpha: 0.6),
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                labelResolver: (_) => AppLocalizations.of(context).chartGoal,
                style: theme.textTheme.labelSmall,
              ),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              history.length,
              (i) => FlSpot(i.toDouble(), history[i].value),
            ),
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
