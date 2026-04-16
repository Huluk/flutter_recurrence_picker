// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'recurrence_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class RecurrenceLocalizationsDe extends RecurrenceLocalizations {
  RecurrenceLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get decrementInterval => 'Wiederholungsintervall verringern';

  @override
  String get endOfMonthHint => 'Dieser Tag existiert nicht in jedem Monat.';

  @override
  String get endOfMonthPreviousDay => 'Oder vorheriger Tag';

  @override
  String get endOfMonthSkip => 'Überspringen';

  @override
  String get endOfMonthAnnotationPreviousDay =>
      'oder vorheriger verfügbarer Tag';

  @override
  String get endOfMonthAnnotationSkip =>
      'übersprungen wenn Datum nicht existiert';

  @override
  String get every => 'Alle';

  @override
  String get frequencyDays => 'Tage';

  @override
  String get frequencyMonths => 'Monate';

  @override
  String get frequencyWeeks => 'Wochen';

  @override
  String get frequencyYears => 'Jahre';

  @override
  String get incrementInterval => 'Wiederholungsintervall erhöhen';

  @override
  String get interval => 'Intervall';

  @override
  String get monthlyByDate => 'Datum';

  @override
  String get monthlyByWeekday => 'Wochentag';

  @override
  String get on => 'Benutzerdefiniert';

  @override
  String get onConnector => 'am';

  @override
  String get ordinalFirst => '1.';

  @override
  String get ordinalFourth => '4.';

  @override
  String get ordinalLast => 'Letzter';

  @override
  String get ordinalSecondToLast => 'Vorletzter';

  @override
  String get ordinalSecond => '2.';

  @override
  String get ordinalThird => '3.';

  @override
  String get weekdayDay => 'Tag';

  @override
  String get weekdayWorkDay => 'Arbeitstag';

  @override
  String get weekdayWeekendDay => 'Wochenendtag';
}
