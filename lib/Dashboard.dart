import 'dart:async';
import 'package:flutter/material.dart';
import 'add_habit_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _currentTime = DateTime.now();
  late final Timer _clockTimer;
  int _numberOfCheckIns = 0;
  final int _goal = 7;

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
            OutlinedButton(
                onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const add_habit_Screen(),
                        ),
                    );
                },
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
      body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
            

                    OutlinedButton(
                        style: OutlinedButton.styleFrom(
                        minimumSize: const Size(220, 48),
                        ),
                        onPressed: _numberOfCheckIns < _goal
                        ? () {
                            setState((){
                            
                                _numberOfCheckIns++;
                            });
                        }
                        : null,
                    child: const Text('Check In'),

                    ),

                    const SizedBox(height: 16),
                    Text('Progress: $_numberOfCheckIns / $_goal'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                        value: _numberOfCheckIns / _goal,
                        ),
                ],
            ),
        ),

      

      );
  }
}