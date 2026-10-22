import 'dart:async';
import 'package:flutter/material.dart';
import 'add_habit_screen.dart';
import 'database_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
/////////////////////////////STORES CLOCK, HABITS, and LOADING STATUS////////////////////////////////////////////////////////
  DateTime _currentTime = DateTime.now();
  late final Timer _clockTimer;
  List<Map<String, dynamic>> _habits = [];
  final Set<int> _checkingInIds = {};
  bool _isLoading = true;
  String? _loadError;
/////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////_LOADS HABITS AND STARTS THE CLOCK WHEN OEPN/////////////////////////////////////////////////////
  @override
  void initState() {
    super.initState();
    _loadHabits();


    _clockTimer = Timer.periodic(
  const Duration(seconds: 1),
  (_) {
    final now = DateTime.now();
    final dayChanged = !DateUtils.isSameDay(_currentTime, now);

    setState(() {
      _currentTime = now;
    });

    if (dayChanged) {
      _loadHabits();
    }
  },
);
  }
/////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////_READS SAVED HABITS AND WEEKLY PROGRESS_//////////////////////////////////////////////////////
  Future<void> _loadHabits() async {
  if (!mounted) return;

  setState(() {
    _isLoading = true;
    _loadError = null;
  });

  try {
    final rows = await DatabaseHelper.getHabits();

    if (!mounted) return;

    setState(() {
      _habits = rows
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      _isLoading = false;
    });
  } catch (error) {
    debugPrint('Loading habits failed: $error');

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _loadError = 'Could not load habits.';
    });
  }
}

/////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////_OPENS THE APP/EDIT AND REFRESEHES THE DASHBOARD AFTER_//////////////////////////////////////////////////////

Future<void> _openHabit({Map<String, dynamic>? habit}) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddHabitScreen(habit: habit),
    ),
  );

  if (!mounted) return;

  await _loadHabits();
}

/////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////_SAVES TODAY CHECK IN AND REFRESHES THE PROGRESS///////////////////////////////////////////////////

Future<void> _checkIn(int habitId) async {
  if (_checkingInIds.contains(habitId)) return;

  setState(() {
    _checkingInIds.add(habitId);
  });

  try {
    await DatabaseHelper.checkIn(habitId);
    await _loadHabits();
  } catch (error) {
    debugPrint('Check-in failed: $error');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not save check-in.')),
    );
  } finally {
    if (mounted) {
      setState(() {
        _checkingInIds.remove(habitId);
      });
    }
  }
}

/////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////_STOPS CLOCK WHEN SCREEN IS REMOVED_/////////////////////////////////////////////////////

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }
/////////////////////////////////////////////////////////////////////////////////////

///////////////////////ADDS THE BOTTOM DASHBOARD/////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(_currentTime).format(context);

    return Scaffold(

      bottomNavigationBar: NavigationBar(
  selectedIndex: 0,
  onDestinationSelected: (index) {
    if (index == 1) {
      _openHabit();
    }
  },
  destinations: const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.add_circle_outline),
      label: 'Add Habit',
    ),
  ],
),
/////////////////////////////////////////////////////////////////////////////////////
///
///
//////////////////////////_TOP BAR WITH THE APP TITLE, ADD BUTTON, AND CLOCK_/////////////////////////////////////
      appBar: AppBar(
        title: const Text('Habit Mastery League'),
        centerTitle: true,
////////////////////////////////// TOP ADD HABIT BUTTON //////////////////////////////////
        actions: [
            OutlinedButton(
                onPressed: () => _openHabit(),
                child: const Text("Add Habit")
            ),
        ],
        

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                bottom: 8,
              ),
              child: Text(time),
            ),
          ),
        ),
      ),
/////////////////////////////////////////////////////////////////////////////////////
///
///
//////////////////////////////_MAIN CONTENT WITH SPACING AROUND THE EDGES_/////////////////////////////////////////////
      body: Padding(
            padding: const EdgeInsets.all(16),
            child: _isLoading
    ? const Center(
        child: CircularProgressIndicator(),
      )
    : _loadError != null
        ? Center(
            child: TextButton(
              onPressed: _loadHabits,
              child: Text('$_loadError\nTap to retry'),
            ),
          )
        : _habits.isEmpty
            ? const Center(
                child: Text('Press Add Habit to create your first habit.'),
              )
            : ListView.builder(
                itemCount: _habits.length,
                itemBuilder: (context, index) {
                  final habit = _habits[index];
                  final id = habit['id'] as int;
                  final target = habit['target'] as int;
                  final completed = habit['completed_this_week'] as int;

                  final checkedToday = habit['checked_in_today'] == 1;
                  final goalReached = completed >= target;
                  final busy = _checkingInIds.contains(id);

                  final progress =
                      (completed / target).clamp(0.0, 1.0).toDouble();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(habit['title'] as String),
                            subtitle: Text(habit['category'] as String),
                            trailing: TextButton(
                              onPressed: busy
                                  ? null
                                  : () => _openHabit(habit: habit),
                              child: const Text('Edit'),
                            ),
                          ),
                          if ((habit['reason'] as String).isNotEmpty)
                            Text(habit['reason'] as String),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(220, 48),
                            ),
                            onPressed: checkedToday || goalReached || busy
                                ? null
                                : () => _checkIn(id),
                            child: Text(
                              goalReached
                                  ? 'Goal reached'
                                  : checkedToday
                                      ? 'Checked in today'
                                      : busy
                                          ? 'Saving...'
                                          : 'Check In',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Progress: $completed / $target days this week',
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: progress),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),

      

      );
  }
}