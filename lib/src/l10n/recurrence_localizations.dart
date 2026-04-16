import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'recurrence_localizations_de.dart';
import 'recurrence_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of RecurrenceLocalizations
/// returned by `RecurrenceLocalizations.of(context)`.
///
/// Applications need to include `RecurrenceLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/recurrence_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: RecurrenceLocalizations.localizationsDelegates,
///   supportedLocales: RecurrenceLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the RecurrenceLocalizations.supportedLocales
/// property.
abstract class RecurrenceLocalizations {
  RecurrenceLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static RecurrenceLocalizations? of(BuildContext context) {
    return Localizations.of<RecurrenceLocalizations>(
        context, RecurrenceLocalizations);
  }

  static const LocalizationsDelegate<RecurrenceLocalizations> delegate =
      _RecurrenceLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// Semantic label for button to decrement the recurrence interval
  ///
  /// In en, this message translates to:
  /// **'Decrement recurrence interval'**
  String get decrementInterval;

  /// Hint text explaining why the end-of-month behavior selector is shown
  ///
  /// In en, this message translates to:
  /// **'This day doesn\'t exist in every month.'**
  String get endOfMonthHint;

  /// Use the last available day of the month when the target day doesn't exist
  ///
  /// In en, this message translates to:
  /// **'Or previous day'**
  String get endOfMonthPreviousDay;

  /// Skip months that don't have the target day
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get endOfMonthSkip;

  /// Verbose suffix for clamped end-of-month rules in describeRecurrenceRule
  ///
  /// In en, this message translates to:
  /// **'or previous available day'**
  String get endOfMonthAnnotationPreviousDay;

  /// Verbose suffix for skipped end-of-month rules in describeRecurrenceRule
  ///
  /// In en, this message translates to:
  /// **'skip when date does not exist'**
  String get endOfMonthAnnotationSkip;

  /// Recurrence mode: repeat every N time units
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get every;

  /// Frequency unit for daily recurrence
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get frequencyDays;

  /// Frequency unit for monthly recurrence
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get frequencyMonths;

  /// Frequency unit for weekly recurrence
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get frequencyWeeks;

  /// Frequency unit for yearly recurrence
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get frequencyYears;

  /// Semantic label for button to increment the recurrence interval
  ///
  /// In en, this message translates to:
  /// **'Increment recurrence interval'**
  String get incrementInterval;

  /// Label for the recurrence interval number field
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get interval;

  /// Label for choosing a day-of-month in monthly recurrence
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get monthlyByDate;

  /// Label for choosing nth weekday in monthly recurrence
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get monthlyByWeekday;

  /// Recurrence mode: on specific days/dates
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get on;

  /// Connecting word in phrases like 'every 2 weeks on Monday'
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get onConnector;

  /// Ordinal for the first occurrence of a weekday in a month
  ///
  /// In en, this message translates to:
  /// **'1st'**
  String get ordinalFirst;

  /// Ordinal for the fourth occurrence of a weekday in a month
  ///
  /// In en, this message translates to:
  /// **'4th'**
  String get ordinalFourth;

  /// Ordinal for the last occurrence of a weekday in a month
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get ordinalLast;

  /// Ordinal for the second-to-last occurrence of a weekday in a month
  ///
  /// In en, this message translates to:
  /// **'2nd to last'**
  String get ordinalSecondToLast;

  /// Ordinal for the second occurrence of a weekday in a month
  ///
  /// In en, this message translates to:
  /// **'2nd'**
  String get ordinalSecond;

  /// Ordinal for the third occurrence of a weekday in a month
  ///
  /// In en, this message translates to:
  /// **'3rd'**
  String get ordinalThird;

  /// Special weekday option meaning any day of the week
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get weekdayDay;

  /// Special weekday option meaning a working day (Mon–Fri by default)
  ///
  /// In en, this message translates to:
  /// **'Work day'**
  String get weekdayWorkDay;

  /// Special weekday option meaning a weekend day (Sat–Sun by default)
  ///
  /// In en, this message translates to:
  /// **'Weekend day'**
  String get weekdayWeekendDay;
}

class _RecurrenceLocalizationsDelegate
    extends LocalizationsDelegate<RecurrenceLocalizations> {
  const _RecurrenceLocalizationsDelegate();

  @override
  Future<RecurrenceLocalizations> load(Locale locale) {
    return SynchronousFuture<RecurrenceLocalizations>(
        lookupRecurrenceLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_RecurrenceLocalizationsDelegate old) => false;
}

RecurrenceLocalizations lookupRecurrenceLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return RecurrenceLocalizationsDe();
    case 'en':
      return RecurrenceLocalizationsEn();
  }

  throw FlutterError(
      'RecurrenceLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
