import 'package:collection/collection.dart';
import 'package:rrule/rrule.dart';

import 'l10n/recurrence_localizations.dart';
import 'rrule_utils.dart';

/// Creates the appropriate [RruleL10n] for the given [languageCode].
///
/// Falls back to English for unsupported languages.
/// Add new cases here as the rrule package gains locale support.
Future<RruleL10n> createRruleL10n(String languageCode) =>
    switch (languageCode) {
      _ => RruleL10nEn.create(),
    };

/// Extension on [RecurrenceRule] that produces a human-readable localized
/// description, using the rrule package's built-in [toText] for the base
/// text and adding end-of-month annotations when needed.
///
/// In **basic** mode (`verbose: false`), an asterisk (`*`) is appended
/// when the rule targets a day that doesn't exist in every applicable
/// month (e.g. the 31st).
///
/// In **verbose** mode, a localized explanation is appended instead,
/// e.g. "Monthly on the 31st day of the month (or previous available day)"
/// or "Monthly on the 31st day of the month (skip when date does not exist)".
extension RecurrenceRuleDescription on RecurrenceRule {
  /// Converts this [RecurrenceRule] into a human-readable localized string.
  ///
  /// If [startDate] is provided, it is used to infer the target month
  /// for yearly rules that lack `BYMONTH`, enabling more precise
  /// end-of-month detection.
  String describe({
    required RruleL10n l10n,
    required RecurrenceLocalizations loc,
    bool verbose = false,
    DateTime? startDate,
  }) {
    final isClamped = hasEndOfMonthClamping;
    final isSkip = !isClamped && expand(startDate)._hasUnsupportedDay();
    final normalized = isClamped ? _normalizeEndOfMonth : this;

    String text;
    if (normalized.canFullyConvertToText) {
      text = normalized.toText(l10n: l10n);
    } else {
      // Fallback: use the RRULE string representation.
      // TODO log
      text = normalized.toString();
    }

    if (isClamped || isSkip) {
      if (verbose) {
        final suffix = isClamped
            ? loc.endOfMonthAnnotationPreviousDay
            : loc.endOfMonthAnnotationSkip;
        text += ' ($suffix)';
      } else {
        text += '*';
      }
    }

    return text;
  }

  /// Encodes the start time into the recurrence repeats.
  RecurrenceRule expand(DateTime? startTime) => switch (frequency) {
        Frequency.weekly when !hasByWeekDays => copyWith(byWeekDays: [
            ByWeekDayEntry(startTime?.weekday ?? DateTime.monday)
          ]),
        Frequency.monthly when !hasByWeekDays && !hasByMonthDays =>
          copyWith(byMonthDays: [startTime?.day ?? 31]),
        Frequency.yearly when !hasByWeekDays && !hasByMonthDays => copyWith(
            byMonths: [startTime?.month ?? 2],
            byMonthDays: [startTime?.day ?? 31]),
        Frequency.yearly when !hasByMonths =>
          copyWith(byMonths: [startTime?.month ?? 2]),
        _ => this,
      };

  /// Returns `true` if this rule targets a day of month that doesn't exist
  /// in every applicable month (e.g. day 31 in a 30-day month).
  bool _hasUnsupportedDay() => switch (frequency) {
        Frequency.monthly when hasByMonthDays => byMonthDays.max > 28,
        Frequency.monthly => false,
        Frequency.yearly when hasByMonthDays =>
          byMonthDays.max > minDaysInMonths(byMonths),
        _ => false,
      };

  /// Strips our end-of-month clamping convention so that rrule's built-in text
  /// encoder can produce a clean description.
  RecurrenceRule get _normalizeEndOfMonth =>
      copyWith(byMonthDays: [byMonthDays.last], bySetPositions: []);
}
