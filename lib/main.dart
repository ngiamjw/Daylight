import 'package:calendar/pages/new_home_page.dart';
import 'package:calendar/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar/database/habit_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();

  await HabitDatabase.initialise();
  await HabitDatabase().saveFirstLaunchDate();

  runApp(MultiProvider(providers: [
    //habit provider
    ChangeNotifierProvider(create: (context) => HabitDatabase()),
    //theme provider
    ChangeNotifierProvider(create: (context) => ThemeProvider())
  ], child: const MyApp()));

  // need flutter pub add provider to get this
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: Provider.of<ThemeProvider>(context).themeData,
        home: NewHomePage());
  }
}
