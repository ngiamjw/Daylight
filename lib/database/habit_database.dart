import 'package:calendar/models/app_settings.dart';
import 'package:calendar/models/habit.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class HabitDatabase extends ChangeNotifier {
  static late Isar isar;
  //SETUP

  //INITIALISE DATABASE
  static Future<void> initialise() async {
    final dir = await getApplicationDocumentsDirectory();
    isar =
        await Isar.open([HabitSchema, AppSettingsSchema], directory: dir.path);
  }

  //save first date of app startup (for heatmap)
  Future<void> saveFirstLaunchDate() async {
    final existingSettings = await isar.appSettings.where().findFirst();
    if (existingSettings == null) {
      final settings = AppSettings()..firstLaunchDate = DateTime.now();
      await isar.writeTxn(() => isar.appSettings.put(settings));
    }
  }

  //get first date of app startup (for heatmap)
  Future<DateTime?> getFirstLaunchDate() async {
    final settings = await isar.appSettings.where().findFirst();
    return settings?.firstLaunchDate;
  }

  //CRUD OPERATIONS

  //LIST OF HABITS
  final List<Habit> currentHabits = [];

  //CREATE
  Future<void> addHabit(String habitName, DateTime date) async {
    //create new habit
    final newHabit = Habit()
      ..name = habitName
      ..createdDate = date;

    //save to db
    await isar.writeTxn(() => isar.habits.put(newHabit));
    // re-read from db
    readhabits();
  }

  //READ
  Future<void> readhabits() async {
    //fetch all habits from db
    List<Habit> fetchedHabits = await isar.habits.where().findAll();

    //give to current habits
    currentHabits.clear();
    currentHabits.addAll(fetchedHabits);

    //update UI
    notifyListeners();
  }

  //UPDATE
  Future<void> updateHabitCompletion(int id, bool isCompleted) async {
    //find specific habit
    final habit = await isar.habits.get(id);

    //update completion status
    if (habit != null) {
      await isar.writeTxn(() async {
        //if habit completed, add to completedDays list
        if (isCompleted && !habit.completedDays.contains(DateTime.now())) {
          //today
          final habit_day = habit.createdDate;

          //add the current date if its not in the list
          habit.completedDays
              .add(DateTime(habit_day.year, habit_day.month, habit_day.day));
        }
        //if habit not completed, remove current date from the list
        else {
          final habit_day = habit.createdDate;
          habit.completedDays.removeWhere((date) =>
              date.year == habit_day.year &&
              date.month == habit_day.month &&
              date.day == habit_day.day);
        }
        //save the updated habits back to the db
        await isar.habits.put(habit);
      });
    }
    readhabits();
  }

  //UPDATE NAME
  Future<void> updateHabitName(int id, String newName) async {
    //find the specific habit
    final habit = await isar.habits.get(id);

    //update habit name
    if (habit != null) {
      await isar.writeTxn(() async {
        habit.name = newName;

        await isar.habits.put(habit);
      });
    }
    readhabits();
  }

  //DELETE
  Future<void> deleteHabit(int id) async {
    await isar.writeTxn(() async {
      await isar.habits.delete(id);
    });
  }
}
