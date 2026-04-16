# recurrence_picker

A Flutter widget for building [RFC 5545](https://tools.ietf.org/html/rfc5545)
recurrence rules (`RRULE`). Built on top of the
[rrule](https://pub.dev/packages/rrule) package.

## Features

- **RecurrencePicker** — compound widget with two modes:
  - *Every* — simple interval + frequency ("every 2 weeks")
  - *Custom* — detailed day/weekday/month selection
- **End-of-month handling** — automatic clamping for days that don't
  exist in every month (e.g. the 31st), with user-facing behavior
  selector

## Current State
This widget is in an early state and may still have some issues.
While the code itself should be reasonable, all the test cases
are AI-generated and I haven't really sorted them out all that much.
The widget APIs are on a level suitable for my application, but feel free to
make a pull request to improve it for your use case.

## Usage

### RecurrencePicker widget

```dart
import 'package:recurrence_picker/recurrence_picker.dart';

RecurrencePicker(
  initialFrequency: Frequency.weekly,
  initialInterval: 1,
  startDate: DateTime.now(),
  onRecurrenceChanged: (rule) {
    print(rule); // RRULE:FREQ=WEEKLY;INTERVAL=1;BYDAY=MO
  },
)
```

Add the localization delegates to your `MaterialApp`:

```dart
MaterialApp(
  localizationsDelegates: [
    ...RecurrenceLocalizations.localizationsDelegates,
    // your other delegates
  ],
  supportedLocales: {
    ...RecurrenceLocalizations.supportedLocales,
  },
)
```

## Localization

Fully supported locales: **en**

My picker supports **de** as well, but the `rrule` package supports only English
and Dutch at the moment.

To add a new locale, provide ARB files in `lib/src/l10n/` following
the existing `recurrence_en.arb` template and run `flutter gen-l10n`.
