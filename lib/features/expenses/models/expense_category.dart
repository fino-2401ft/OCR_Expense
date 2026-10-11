import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  study,
  travel,
  devices,
  entertainment;

  String get label => switch (this) {
        ExpenseCategory.food => 'Food',
        ExpenseCategory.study => 'Study',
        ExpenseCategory.travel => 'Travel',
        ExpenseCategory.devices => 'Devices',
        ExpenseCategory.entertainment => 'Entertainment',
      };

  String get storageValue => name;

  IconData get icon => switch (this) {
        ExpenseCategory.food => Icons.restaurant,
        ExpenseCategory.study => Icons.menu_book,
        ExpenseCategory.travel => Icons.directions_bus,
        ExpenseCategory.devices => Icons.devices,
        ExpenseCategory.entertainment => Icons.sports_esports,
      };

  Color get color => switch (this) {
        ExpenseCategory.food => const Color(0xFFE07A3D),
        ExpenseCategory.study => const Color(0xFF3D7AE0),
        ExpenseCategory.travel => const Color(0xFF2AA89A),
        ExpenseCategory.devices => const Color(0xFF7A3DE0),
        ExpenseCategory.entertainment => const Color(0xFFE03D6E),
      };

  static ExpenseCategory fromStorage(String value) {
    return ExpenseCategory.values.firstWhere(
      (c) => c.storageValue == value,
      orElse: () => ExpenseCategory.food,
    );
  }
}
