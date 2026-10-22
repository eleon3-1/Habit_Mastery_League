import 'package:flutter/material.dart';

import 'database_helper.dart';

class AddHabitScreen extends StatefulWidget {
  final Map<String, dynamic>? habit;

  const AddHabitScreen({super.key, this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final titleController = TextEditingController();
  final categoryController = TextEditingController();
  final reasonController = TextEditingController();

  double weeklyTarget = 3;
  bool _isSaving = false;

  final lightGreen = const Color(0xFFA5D6A7);
  final backgroundGreen = const Color(0xFFE8F5E9);
  final sliderGreen = const Color(0xFF66BB6A);

  @override
  void initState() {
    super.initState();

    // Fill in the fields when editing a habit
    if (widget.habit != null) {
      titleController.text = widget.habit!['title'] ?? '';
      categoryController.text = widget.habit!['category'] ?? '';
      reasonController.text = widget.habit!['reason'] ?? '';
      weeklyTarget = (widget.habit!['target'] ?? 3).toDouble();
    }
  }

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

  Future<void> deleteHabit() async {
    if (_isSaving) return;

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
      backgroundColor: backgroundGreen,

      appBar: AppBar(
        backgroundColor: lightGreen,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: Text(isEditing ? 'Edit Habit' : 'Create Habit'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Title', style: TextStyle(fontSize: 16)),

            const SizedBox(height: 8),

            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Enter habit title',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text('Category', style: TextStyle(fontSize: 16)),

            const SizedBox(height: 8),

            TextField(
              controller: categoryController,
              decoration: InputDecoration(
                hintText: 'Enter category',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

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

            const Text('Reason', style: TextStyle(fontSize: 16)),

            const SizedBox(height: 8),

            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Why do you want this habit?',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

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
