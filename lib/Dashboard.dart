import 'dart:async';
import 'package:flutter/material.dart';
import 'add_habit.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _currentTime = DateTime.now();
  late final Timer _clockTimer;

  @override
  void initState() {
    super.initState();

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        setState(() {
          _currentTime = DateTime.now();
        });
      },
    );
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(_currentTime).format(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Mastery League'),
        centerTitle: true,
        actions: [
            TextButton(
                onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const add_habit_Screen().
                        ),
                    );
                },
                child: const Text("Add Habit")
            )
        ]





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
      




    );
  }
}