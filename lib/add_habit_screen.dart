import 'package:flutter/material.dart';

import 'database_helper.dart';

class AddHabitScreen extends StatefulWidget {
  final Map<String, dynamic>? habit;

  const AddHabitScreen({super.key, this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  ///////////(TEXT BOXES, TARGET SLIDER VALUE, AND SAVING STATUS)/////////////
  final titleController = TextEditingController();
  final categoryController = TextEditingController();
  final reasonController = TextEditingController();

  double weeklyTarget = 3;
  bool _isSaving = false;

  ///////////(SCREEN COLORS)/////////////
  final lightGreen = const Color(0xFFA5D6A7);
  final backgroundGreen = const Color(0xFFE8F5E9);
  final sliderGreen = const Color(0xFF66BB6A);

  @override
  void initState() {
    super.initState();

    ///////////(FILLS IN THE FIELDS WHEN EDITING A HABIT)/////////////
    if (widget.habit != null) {
      titleController.text = widget.habit!['title'] ?? '';
      categoryController.text = widget.habit!['category'] ?? '';
      reasonController.text = widget.habit!['reason'] ?? '';
      weeklyTarget = (widget.habit!['target'] ?? 3).toDouble();
    }
  }

  ///////////(CHECKS THE FIELDS, SAVES THE HABIT, AND GOES BACK)/////////////
  Future<void> saveHabit() async {
    if (_isSaving) return;

    final title = titleController.text.trim();
    final category = categoryController.text.trim();

    if (title.isEmpty || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and category')),
      );
      return;
    }

    final habit = <String, dynamic>{
      'id': widget.habit?['id'],
      'title': title,
      'category': category,
      'target': weeklyTarget.toInt(),
      'reason': reasonController.text.trim(),
    };

    setState(() {
      _isSaving = true;
    });

    try {
      habit['id'] = await DatabaseHelper.saveHabit(habit);

      if (!mounted) return;
      Navigator.pop(context, habit);
    } catch (error) {
      debugPrint('Habit save failed: $error');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save habit. Please try again.'),
        ),
      );
    }
  }

  ///////////(DELETES THE HABIT AND GOES BACK)/////////////
  Future<void> deleteHabit() async {
    if (_isSaving) return;

    ///////////(ASKS BEFORE DELETING, BECAUSE IT ALSO DELETES ALL ITS CHECK-INS)/////////////
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete habit?'),
        content: const Text('This also deletes all of its check-ins.'),
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

    if (confirmed != true || !mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final id = widget.habit?['id'] as int?;

      if (id != null) {
        await DatabaseHelper.deleteHabit(id);
      }

      if (!mounted) return;
      Navigator.pop(context, {'deleted': true});
    } catch (error) {
      debugPrint('Habit deletion failed: $error');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete habit. Please try again.'),
        ),
      );
    }
  }

  ///////////(CLEANS UP THE TEXT BOXES WHEN THE SCREEN CLOSES)/////////////
  @override
  void dispose() {
    titleController.dispose();
    categoryController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.habit != null;

    return Scaffold(
      ///////////(GREEN BACKGROUND IN LIGHT MODE)/////////////
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : backgroundGreen,

      ///////////(CREATE OR EDIT TITLE)/////////////
      appBar: AppBar(
        backgroundColor: lightGreen,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: Text(isEditing ? 'Edit Habit' : 'Create Habit'),
      ),

      ///////////(HABIT FORM)/////////////
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ///////////(TITLE BOX)/////////////
            const Text('Title', style: TextStyle(fontSize: 16)),

            const SizedBox(height: 8),

            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Enter habit title',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            ///////////(CATEGORY BOX)/////////////
            const Text('Category', style: TextStyle(fontSize: 16)),

            const SizedBox(height: 8),

            TextField(
              controller: categoryController,
              decoration: InputDecoration(
                hintText: 'Enter category',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            ///////////(WEEKLY TARGET SLIDER, 1 TO 7 DAYS)/////////////
            Text(
              'Weekly Target: ${weeklyTarget.toInt()} days',
              style: const TextStyle(fontSize: 16),
            ),

            Slider(
              value: weeklyTarget,
              min: 1,
              max: 7,
              divisions: 6,
              activeColor: sliderGreen,
              inactiveColor: const Color(0xFFC8E6C9),
              label: weeklyTarget.toInt().toString(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        weeklyTarget = value;
                      });
                    },
            ),

            const SizedBox(height: 20),

            ///////////(REASON BOX)/////////////
            const Text('Reason', style: TextStyle(fontSize: 16)),

            const SizedBox(height: 8),

            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Why do you want this habit?',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            ///////////(SAVE OR UPDATE BUTTON)/////////////
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: lightGreen,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : saveHabit,
                child: Text(isEditing ? 'Update Habit' : 'Save Habit'),
              ),
            ),

            const SizedBox(height: 10),

            ///////////(DELETE BUTTON, ONLY WHEN EDITING)/////////////
            if (isEditing)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: _isSaving ? null : deleteHabit,
                  child: const Text('Delete Habit'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
