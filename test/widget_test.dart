import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_mastery_league/add_habit_screen.dart';
import 'package:habit_mastery_league/habit_detail_screen.dart';

const Map<String, dynamic> _sampleHabit = {
  'id': 42,
  'title': 'Reading',
  'category': 'Study',
  'reason': 'Build focus',
  'target': 4,
  'completed_this_week': 2,
};

Finder _field(String hint) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.hintText == hint,
    description: 'TextField with hint "$hint"',
  );
}

Future<void> _showScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('AddHabitScreen', () {
    ////////////////////////_TEST_1/////////////////////////////////////////////
    testWidgets('changing the target to five preserves entered text', (
      tester,
    ) async {
      await _showScreen(tester, const AddHabitScreen());
      expect(find.text('Weekly Target: 3 days'), findsOneWidget);
      await tester.enterText(_field('Enter habit title'), 'Daily Reading');
      await tester.enterText(_field('Enter category'), 'Study');

      final slider = find.byType(Slider);
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      final bounds = tester.getRect(slider);
    
      await tester.tapAt(
        Offset(bounds.left + bounds.width * 2 / 3, bounds.center.dy),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weekly Target: 5 days'), findsOneWidget);
      expect(tester.widget<Slider>(slider).value, 5.0);
      expect(find.text('Daily Reading'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
    });
/////////////////////////////////////END_OF_TEST_1/////////////////////////////////////////////
///

////////////////////////////////////////_TEST_2/////////////////////////////////////////////
    testWidgets('rejects an empty title and keeps the form open', (tester) async {
      await _showScreen(tester, const AddHabitScreen());
      await tester.enterText(_field('Enter category'), 'Study');

      await _tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Save Habit'),
      );

      expect(
        find.text('Please enter a title and category'),
        findsOneWidget,
      );


      expect(find.byType(AddHabitScreen), findsOneWidget);
      expect(
        find.text('Could not save habit. Please try again.'),
        findsNothing,
      );
    });
/////////////////////////////////////_END_OF_TEST_2/////////////////////////////////////////////

/////////////////////////////////////_TEST_3/////////////////////////////////////////////
    testWidgets('editing loads the selected habit into the form', (tester) async {
      await _showScreen(
        tester,
        const AddHabitScreen(habit: _sampleHabit),
      );



      expect(find.text('Edit Habit'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
      expect(find.text('Build focus'), findsOneWidget);
      expect(find.text('Weekly Target: 4 days'), findsOneWidget);
      expect(find.text('Update Habit'), findsOneWidget);
      expect(find.text('Delete Habit'), findsOneWidget);
    });
/////////////////////////////////////_END_OF_TEST_3/////////////////////////////////////////////



/////////////////////////////////////_TEST_4/////////////////////////////////////////////
    testWidgets('canceling deletion keeps the form and unsaved edits', (
      tester,
    ) async {
      await _showScreen(
        tester,
        const AddHabitScreen(habit: _sampleHabit),
      );
      await tester.enterText(_field('Enter habit title'), 'Daily Reading');

      await _tapVisible(
        tester,
        find.widgetWithText(OutlinedButton, 'Delete Habit'),
      );



      expect(find.text('Delete habit?'), findsOneWidget);
      expect(
        find.text('This also deletes all of its check-ins.'),
        findsOneWidget,
      );

      await _tapVisible(
        tester,
        find.widgetWithText(TextButton, 'Cancel'),
      );

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(AddHabitScreen), findsOneWidget);
      await tester.ensureVisible(_field('Enter habit title'));
      await tester.pumpAndSettle();
      expect(find.text('Daily Reading'), findsOneWidget);
      expect(find.text('Weekly Target: 4 days'), findsOneWidget);
    });
/////////////////////////////////////_END_OF_TEST_4/////////////////////////////////////////////
  });

/////////////////////////////////////TEST_t/////////////////////////////////////////////

  group('HabitDetailScreen', () {
    testWidgets('shows the selected habit with correct partial progress', (
      tester,
    ) async {
      await _showScreen(
        tester,
        const HabitDetailScreen(habit: _sampleHabit),
      );

      expect(find.text('Habit Details'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
      expect(find.text('Build focus'), findsOneWidget);
      expect(find.text('4 days per week'), findsOneWidget);
      expect(find.text('2 / 4 days this week'), findsOneWidget);
      expect(
        tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        ).value,
        closeTo(0.5, 0.000001),
      );
    });

  });
}

/////////////////////////////////////_END_OF_TEST_5/////////////////////////////////////////////