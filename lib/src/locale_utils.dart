import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbols.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'l10n/recurrence_localizations.dart';

typedef WeekdayListGenerator = List<int> Function(DateSymbols);

enum WeekdayChoice {
  monday(DateTime.monday),
  tuesday(DateTime.tuesday),
  wednesday(DateTime.wednesday),
  thursday(DateTime.thursday),
  friday(DateTime.friday),
  saturday(DateTime.saturday),
  sunday(DateTime.sunday),

  anyDay(null, generator: _week),
  workDay(null, generator: _workDays),
  weekendDay(null, generator: _weekendDays),
  ;

  final int? wday;
  final WeekdayListGenerator? generator;

  const WeekdayChoice(this.wday, {this.generator})
      : assert(wday != null || generator != null);

  static WeekdayChoice fromValue(int value) =>
      values.singleWhere((v) => v.wday == value);

  List<int> days(DateSymbols symbols) =>
      generator == null ? [wday!] : generator!(symbols);

  /// Returns the localized label.
  String label(RecurrenceLocalizations loc) => switch (this) {
        WeekdayChoice.anyDay => loc.weekdayDay,
        WeekdayChoice.workDay => loc.weekdayWorkDay,
        WeekdayChoice.weekendDay => loc.weekdayWeekendDay,
        _ => DateFormat('', loc.localeName)
            .dateSymbols
            .STANDALONESHORTWEEKDAYS[wday! % 7],
      };

  static List<WeekdayChoice> get weekdayValues => const [
        WeekdayChoice.monday,
        WeekdayChoice.tuesday,
        WeekdayChoice.wednesday,
        WeekdayChoice.thursday,
        WeekdayChoice.friday,
        WeekdayChoice.saturday,
        WeekdayChoice.sunday,
      ];

  static List<WeekdayChoice> get collectionValues =>
      values.where((v) => v.wday == null).toList();

  static List<int> _week(DateSymbols _) => const [1, 2, 3, 4, 5, 6, 7];

  static List<int> _weekendDays(DateSymbols symbols) => [
        for (int i = symbols.WEEKENDRANGE[0]; i <= symbols.WEEKENDRANGE[1]; i++)
          i + 1
      ];

  static List<int> _workDays(DateSymbols symbols) {
    final weekendDays = _weekendDays(symbols).toSet();
    return _week(symbols).whereNot(weekendDays.contains).toList();
  }
}

/// Resolves [DateSymbols] for the current locale.
DateSymbols dateSymbolsOf(BuildContext context) {
  final locale = RecurrenceLocalizations.of(context)!.localeName;
  return DateFormat('', locale).dateSymbols;
}

/// Short month name for a 1-indexed month
/// (1 = January … 12 = December).
String monthName(DateSymbols symbols, int month) =>
    symbols.STANDALONESHORTMONTHS[month - 1];
