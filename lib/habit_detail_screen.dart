import 'package:flutter/material.dart';

class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.habit});

  final Map<String, dynamic> habit;

  @override
  Widget build(BuildContext context) {
    final title = habit['title'] as String;
    final category = (habit['category'] as String).trim();
    final reason = (habit['reason'] as String).trim();
    final target = habit['target'] as int;
    final completed = habit['completed_this_week'] as int;

    final progress = target > 0
        ? (completed / target).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Habit Details'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _infoCard(
              context,
              'Category',
              category.isEmpty ? 'Uncategorized' : category,
            ),
            _infoCard(
              context,
              'Weekly target',
              target == 1 ? '1 day per week' : '$target days per week',
            ),
            _infoCard(
              context,
              'Reason',
              reason.isEmpty ? 'No reason added.' : reason,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly progress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('$completed / $target days this week'),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: progress, minHeight: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(value),
          ],
        ),
      ),
    );
  }
}
