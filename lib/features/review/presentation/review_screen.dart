import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/vnd_format.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/models/expense.dart';
import '../../expenses/models/expense_category.dart';
import '../../parser/parsed_receipt.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.imageFile,
    required this.parsed,
    this.existing,
  });

  final File imageFile;
  final ParsedReceipt parsed;
  final Expense? existing;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ExpenseRepository();

  late final TextEditingController _merchant;
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  late DateTime _date;
  late ExpenseCategory _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _merchant = TextEditingController(
      text: e?.merchant ?? widget.parsed.merchant ?? '',
    );
    _amount = TextEditingController(
      text: (e?.amountVnd ?? widget.parsed.amountVnd)?.toString() ?? '',
    );
    _notes = TextEditingController(text: e?.notes ?? '');
    _date = e?.date ?? widget.parsed.date ?? DateTime.now();
    _category = e?.category ?? ExpenseCategory.food;
  }

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final amount = parseVndInput(_amount.text);
      if (amount == null || amount <= 0) {
        throw StateError('Invalid amount');
      }

      String? imagePath = widget.existing?.imagePath;
      String? thumbPath = widget.existing?.thumbnailPath;

      final editingSameFile = widget.existing != null &&
          widget.existing!.imagePath == widget.imageFile.path;
      if (!editingSameFile) {
        final saved =
            await _repo.storage.saveReceiptImages(widget.imageFile);
        imagePath = saved.$1;
        thumbPath = saved.$2;
      }

      final expense = Expense(
        id: widget.existing?.id,
        merchant: _merchant.text.trim(),
        amountVnd: amount,
        date: _date,
        category: _category,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        thumbnailPath: thumbPath,
        imagePath: imagePath,
        ocrRawText: widget.parsed.rawText.isEmpty
            ? widget.existing?.ocrRawText
            : widget.parsed.rawText,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );

      if (expense.id == null) {
        await _repo.insert(expense);
      } else {
        await _repo.update(expense);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd/MM/yyyy').format(_date);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Review receipt' : 'Edit expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.file(widget.imageFile, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _merchant,
              decoration: const InputDecoration(
                labelText: 'Merchant',
                prefixIcon: Icon(Icons.storefront),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Merchant is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (VND)',
                prefixIcon: Icon(Icons.payments),
                hintText: '150000',
              ),
              validator: (v) {
                final n = parseVndInput(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(dateLabel),
              trailing: TextButton(
                onPressed: _pickDate,
                child: const Text('Change'),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ExpenseCategory>(
              // ignore: deprecated_member_use
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              items: ExpenseCategory.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Icon(c.icon, color: c.color, size: 20),
                          const SizedBox(width: 8),
                          Text(c.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (c) {
                if (c != null) setState(() => _category = c);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            if (widget.parsed.rawText.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('OCR text'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        widget.parsed.rawText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save expense'),
            ),
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
