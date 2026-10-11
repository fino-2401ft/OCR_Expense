import 'package:flutter/material.dart';

import '../../../core/utils/vnd_format.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/models/expense_category.dart';
import '../painters/bar_chart_painter.dart';
import '../painters/donut_chart_painter.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, this.refreshToken = 0});

  final int refreshToken;

  @override
  State<AnalyticsScreen> createState() => AnalyticsScreenState();
}

class AnalyticsScreenState extends State<AnalyticsScreen> {
  final _repo = ExpenseRepository();
  late Future<_AnalyticsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant AnalyticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      reload();
    }
  }

  Future<_AnalyticsData> _load() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final byCategory = await _repo.totalsByCategory(
      from: monthStart,
      to: monthEnd,
    );
    final weekly = await _repo.weeklyTotals(now);
    final weekTotal = weekly.fold<int>(0, (s, v) => s + v);
    final monthTotal = byCategory.values.fold<int>(0, (s, v) => s + v);
    return _AnalyticsData(
      byCategory: byCategory,
      weekly: weekly,
      weekTotal: weekTotal,
      monthTotal: monthTotal,
    );
  }

  void reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AnalyticsData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Failed to load: ${snap.error}'));
        }
        final data = snap.data!;
        final slices = ExpenseCategory.values
            .map((c) => DonutSlice(category: c, amount: data.byCategory[c] ?? 0))
            .toList();
        final hasCategoryData = slices.any((s) => s.amount > 0);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('This week: ${formatVnd(data.weekTotal)}'),
                    Text('This month: ${formatVnd(data.monthTotal)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'By category (this month)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: CustomPaint(
                        painter: DonutChartPainter(slices: slices),
                        child: Center(
                          child: Text(
                            hasCategoryData ? 'Spend' : 'No data',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...slices.map((s) {
                      final total = data.monthTotal;
                      final pct = total == 0
                          ? 0
                          : ((s.amount / total) * 100).round();
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 8,
                          backgroundColor: s.category.color,
                        ),
                        title: Text(s.category.label),
                        trailing: Text(
                          '${formatVnd(s.amount)} · $pct%',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This week (Mon–Sun)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: BarChartPainter(
                      values: data.weekly,
                      labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnalyticsData {
  _AnalyticsData({
    required this.byCategory,
    required this.weekly,
    required this.weekTotal,
    required this.monthTotal,
  });

  final Map<ExpenseCategory, int> byCategory;
  final List<int> weekly;
  final int weekTotal;
  final int monthTotal;
}
