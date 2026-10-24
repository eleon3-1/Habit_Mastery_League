import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'settings_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  ///////////(STORES THE HABITS AND THIS WEEK'S CHECK-INS)/////////////
  List<Map<String, Object?>> _habits = [];
  List<Map<String, Object?>> _checkIns = [];

  ///////////(TODAY AND THIS WEEK'S MONDAY)/////////////
  final _today = DateUtils.dateOnly(DateTime.now());
  late final _monday = DateUtils.addDaysToDate(_today, 1 - _today.weekday);

  ///////////(LOADS EVERYTHING WHEN THE SCREEN OPENS)/////////////
  @override
  void initState() {
    super.initState();
    _load();
  }

  ///////////(TURNS A DATE INTO TEXT LIKE 2026-10-24 FOR THE DATABASE)/////////////
  String _key(DateTime date) => date.toIso8601String().split('T').first;

  ///////////(TURNS DATABASE TEXT INTO "Sat, Oct 24" FOR THE SCREEN)/////////////
  String _pretty(String date) =>
      MaterialLocalizations.of(context).formatMediumDate(DateTime.parse(date));

  ///////////(READ: GETS ALL HABITS AND THIS WEEK'S CHECK-INS)/////////////
  Future<void> _load() async {
    try {
      final habits = await DatabaseHelper.getHabits();
      final checkIns = await DatabaseHelper.getWeekCheckIns();

      if (!mounted) return;

      setState(() {
        _habits = habits;
        _checkIns = checkIns;
      });
    } catch (error) {
      debugPrint('Loading history failed: $error');
      _showMessage('Could not load history.');
    }
  }

  ///////////(SHOWS A SHORT MESSAGE AT THE BOTTOM)/////////////
  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  ///////////(PICKS A DAY FROM THIS WEEK, NO FUTURE DAYS)/////////////
  Future<DateTime?> _pickDate(DateTime start) {
    return showDatePicker(
      context: context,
      initialDate: start,
      firstDate: _monday,
      lastDate: _today,
    );
  }

  ///////////(SAVES A CHANGE, RELOADS, AND SHOWS A MESSAGE IF IT FAILS)/////////////
  Future<void> _save(Future<void> Function() action, String error) async {
    try {
      await action();
      await _load();
    } catch (_) {
      _showMessage(error);
    }
  }

  ///////////(CREATE: ADDS A CHECK-IN ON A PICKED DAY)/////////////
  Future<void> _add(int habitId) async {
    final date = await _pickDate(_today);
    if (date == null) return;

    await _save(
      () => DatabaseHelper.addCheckIn(habitId, _key(date)),
      'That day already has a check-in.',
    );
  }

  ///////////(UPDATE: MOVES A CHECK-IN TO A DIFFERENT DAY)/////////////
  Future<void> _edit(Map<String, Object?> checkIn) async {
    final date = await _pickDate(
      DateTime.parse(checkIn['local_date'] as String),
    );
    if (date == null) return;

    await _save(
      () => DatabaseHelper.updateCheckIn(checkIn['id'] as int, _key(date)),
      'That day already has a check-in.',
    );
  }

  ///////////(DELETE: ASKS FIRST, THEN REMOVES THE CHECK-IN)/////////////
  Future<void> _delete(Map<String, Object?> checkIn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete check-in?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _save(
      () => DatabaseHelper.deleteCheckIn(checkIn['id'] as int),
      'Could not delete check-in.',
    );
  }

  ///////////(WEEKLY RATE: DAYS DONE OUT OF THE TARGET, PERCENT STOPS AT 100)/////////////
  String _progress(Map<String, Object?> habit, int done) {
    final target = habit['target'] as int;
    final percent = (done.clamp(0, target) / target * 100).round();
    return '$done of $target days this week ($percent%)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      ///////////(HISTORY TITLE)/////////////
      appBar: AppBar(title: const Text('History'), centerTitle: true),

      ///////////(EVERY HABIT WITH ITS CHECK-INS THIS WEEK)/////////////
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ///////////(SHOWS A MESSAGE WHEN THERE ARE NO HABITS)/////////////
          if (_habits.isEmpty)
            const ListTile(
              leading: Icon(Icons.history),
              title: Text('No habits yet.'),
            ),

          for (final habit in _habits) ...[
            ///////////(HABIT NAME, WEEKLY PROGRESS, AND ADD CHECK-IN BUTTON)/////////////
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(habit['title'] as String),
              subtitle: Text(
                _progress(
                  habit,
                  _checkIns.where((c) => c['habit_id'] == habit['id']).length,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add check-in',
                onPressed: () => _add(habit['id'] as int),
              ),
            ),

            ///////////(ONE ROW PER CHECK-IN WITH EDIT AND DELETE BUTTONS)/////////////
            for (final checkIn in _checkIns.where(
              (c) => c['habit_id'] == habit['id'],
            ))
              ListTile(
                contentPadding: const EdgeInsets.only(left: 56, right: 16),
                title: Text(_pretty(checkIn['local_date'] as String)),
                trailing: Wrap(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                      onPressed: () => _edit(checkIn),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete',
                      onPressed: () => _delete(checkIn),
                    ),
                  ],
                ),
              ),

            const Divider(),
          ],
        ],
      ),

      ///////////(BOTTOM NAVIGATION)/////////////
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index != 1) {
            Navigator.pop(context, index);
          }
        },
        destinations: habitDestinations,
      ),
    );
  }
}
