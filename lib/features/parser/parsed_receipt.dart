class ParsedReceipt {
  final String? merchant;
  final int? amountVnd;
  final DateTime? date;
  final String rawText;

  const ParsedReceipt({
    this.merchant,
    this.amountVnd,
    this.date,
    required this.rawText,
  });
}
