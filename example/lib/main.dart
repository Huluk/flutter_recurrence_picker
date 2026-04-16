import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monthly_calendar/monthly_calendar.dart';
import 'package:recurrence_picker/recurrence_picker.dart';
import 'package:rrule/rrule.dart';

import 'l10n/app_localizations.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recurrence Picker Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      localizationsDelegates: [
        ...RecurrenceLocalizations.localizationsDelegates,
        ...CalendarLocalizations.localizationsDelegates,
        AppLocalizations.delegate,
      ],
      supportedLocales: {
        ...RecurrenceLocalizations.supportedLocales,
        ...CalendarLocalizations.supportedLocales,
      },
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _startDate = DateTime.now();
  RecurrenceRule _rule = RecurrenceRule(frequency: Frequency.weekly);

  Future<void> _showStartDateDialog(BuildContext context) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _StartDateDialog(initialDate: _startDate),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.appTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Start date
            _SectionHeader(label: loc.startDate),
            const SizedBox(height: 8),
            _startDatePicker,

            // Recurrence rule
            const SizedBox(height: 16),
            _SectionHeader(label: loc.recurrenceRule),
            const SizedBox(height: 8),
            _recurrencePicker,

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // Results
            _SectionHeader(label: loc.rruleString),
            const SizedBox(height: 4),
            SelectableText(
              _rule.toString(),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            _SectionHeader(label: loc.description),
            const SizedBox(height: 4),
            _RuleDescription(rule: _rule),
          ],
        ),
      ),
    );
  }

  Widget get _startDatePicker {
    final theme = Theme.of(context);
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: theme.colorScheme.surfaceContainerLow,
      leading: const Icon(Icons.calendar_today),
      title: Text(
        DateFormat.yMMMMd().format(_startDate),
        style: theme.textTheme.titleMedium,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showStartDateDialog(context),
    );
  }

  Widget get _recurrencePicker => RecurrencePicker(
        initialFrequency: Frequency.weekly,
        initialInterval: 1,
        startDate: _startDate,
        showEndOfMonthSelector: true,
        onRecurrenceChanged: (rule) {
          setState(() => _rule = rule);
        },
      );
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

/// Displays a human-readable description of a [RecurrenceRule].
class _RuleDescription extends StatefulWidget {
  final RecurrenceRule rule;
  const _RuleDescription({required this.rule});

  @override
  State<_RuleDescription> createState() => _RuleDescriptionState();
}

class _RuleDescriptionState extends State<_RuleDescription> {
  RruleL10n? _l10n;
  String? _languageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode != _languageCode) {
      _languageCode = languageCode;
      _initL10n(languageCode);
    }
  }

  Future<void> _initL10n(String languageCode) async {
    final l10n = await createRruleL10n(languageCode);
    if (mounted && languageCode == _languageCode) {
      setState(() => _l10n = l10n);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_l10n == null) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final text = widget.rule.describe(
      l10n: _l10n!,
      loc: RecurrenceLocalizations.of(context)!,
      verbose: true,
    );
    return Text(text, style: Theme.of(context).textTheme.bodyLarge);
  }
}

/// A dialog that shows a [MonthlyCalendarView] for picking a start date.
class _StartDateDialog extends StatefulWidget {
  final DateTime initialDate;
  const _StartDateDialog({required this.initialDate});

  @override
  State<_StartDateDialog> createState() => _StartDateDialogState();
}

class _StartDateDialogState extends State<_StartDateDialog> {
  late DateTime _selected;
  late final CalendarController _controller;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _controller = CalendarController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select start date'),
      content: SizedBox(
        width: 400,
        child: MonthlyCalendarView(
          today: DateTime.now(),
          controller: _controller,
          selectedDate: _selected,
          onDayTapped: (date) {
            setState(() => _selected = date);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
