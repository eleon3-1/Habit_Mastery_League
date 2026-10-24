import 'package:flutter/material.dart';

///////////////////////////////////////// SHARED APP THEME ////////////////////
final appThemeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
///////////////////////////////////////// NAVIGATION BUTTONS FOR ALL SCREENS ////////////////////
const habitDestinations = [
  NavigationDestination(
    icon: Icon(Icons.home_outlined),
    label: 'Dashboard',
  ),
  NavigationDestination(
    icon: Icon(Icons.add_circle_outline),
    label: 'Add Habit',
  ),
  NavigationDestination(
    icon: Icon(Icons.settings_outlined),
    label: 'Settings',
  ),
];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
///////////////////////////////////////////// SETTINGS TITLE /////////////////////////////////////////
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),

///////////////////////////////////////// SETTINGS OPTIONS ////////////////////
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
///////////////////////////////////////// CHANGES THE APP THEME ////////////////////
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (enabled) {
              appThemeMode.value =
                  enabled ? ThemeMode.dark : ThemeMode.light;
            },
          ),

          const Divider(),

///////////////////////////////////////// DISPLAYS APP INFORMATION ////////////////////
ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About the app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Habit Mastery League'),
                  content: const Text(
                    'Create habits, check in each day, '
                    'and track your weekly progress.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Close'),
                    ), 
                  ], 
                ), 
              ); 
            }, 
          ), 
        ],
      ),

                

///////////////////////////////////////// BOTTOM NAVIGATION ////////////////////
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index != 2) {
            Navigator.pop(context, index);
          }
        },
        destinations: habitDestinations,
      ),
    );
  }
}