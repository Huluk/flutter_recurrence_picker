// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Recurrence Picker Demo';

  @override
  String get startDate => 'Start date';

  @override
  String get recurrenceRule => 'Recurrence rule';

  @override
  String get description => 'Description';

  @override
  String get rruleString => 'RRULE string';
}
