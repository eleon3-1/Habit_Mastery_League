import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'settings_screen.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


///////////////////////////// APPLIES THE SELECTED THEME TO THE APP ////////////////////
@override
Widget build(BuildContext context) {
  return ValueListenableBuilder<ThemeMode>(
    valueListenable: appThemeMode,
    builder: (context, mode, child) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Habit Mastery League',

//////////////////// Light appearance.////////////////////////////////////
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
          ),
        ),

///////////////////////////// Dark appearance.////////////////////////////////////
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
          ),
        ),

        themeMode: mode,
        home: const DashboardScreen(),
      );
    },
  );
} 
} 