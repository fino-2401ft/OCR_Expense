import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/vnd_format.dart';
import '../../parser/parsed_receipt.dart';
import '../../review/presentation/review_screen.dart';
import '../data/expense_repository.dart';
import '../models/expense.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.refreshToken = 0});

  /// Bump from parent to force reload after a successful scan save.
  final int refreshToken;

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _repo = ExpenseRepository();
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      reload();
    }
  }

  Future<_HomeData> _load() async {
    final items = await _repo.getAll();
    final monthTotal = await _repo.monthTotal(DateTime.now());
    return _HomeData(items: items, monthTotal: monthTotal);
  }

  void reload() {
    setState(() => _future = _load());
  }

  Future<void> _confirmDelete(Expense expense) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Remove "${expense.merchant}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.delete(expense);
    reload();
  }

  Future<void> _openEdit(Expense expense) async {
    final filePath = expense.imagePath ?? expense.thumbnailPath;
    if (filePath == null || !File(filePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt image is missing.')),
      );
      return;
    }
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReviewScreen(
          imageFile: File(filePath),
          parsed: ParsedReceipt(rawText: expense.ocrRawText ?? ''),
          existing: expense,
        ),
      ),
    );
    if (saved == true) reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Failed to load: ${snap.error}'));
        }
        final data = snap.data!;
        return RefreshIndicator(
          onRefresh: () async => reload(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This month',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatVnd(data.monthTotal),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (data.items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No expenses yet.\nScan a receipt to start.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: data.items.length,
                  itemBuilder: (context, index) {
                    final e = data.items[index];
                    return Dismissible(
                      key: ValueKey(e.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red.shade400,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        await _confirmDelete(e);
                        return false;
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: e.category.color.withValues(alpha: 0.15),
                          foregroundColor: e.category.color,
                          child: Icon(e.category.icon, size: 20),
                        ),
                        title: Text(e.merchant),
                        subtitle: Text(
                          '${e.category.label} · ${DateFormat('dd/MM/yyyy').format(e.date)}',
                        ),
                        trailing: Text(
                          formatVnd(e.amountVnd),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () => _openEdit(e),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeData {
  _HomeData({required this.items, required this.monthTotal});
  final List<Expense> items;
  final int monthTotal;
}
