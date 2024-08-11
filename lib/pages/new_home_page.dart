import 'package:calendar/components/drawer.dart';
import 'package:calendar/components/habit_tile.dart';
import 'package:calendar/components/new_heatmap.dart';
import 'package:calendar/database/habit_database.dart';
import 'package:calendar/models/habit.dart';
import 'package:calendar/util/habit_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class NewHomePage extends StatefulWidget {
  const NewHomePage({super.key});

  @override
  State<NewHomePage> createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  final TextEditingController mycontroller = TextEditingController();
  DateTime? selectedDate; // State variable to store the selected date

  @override
  void initState() {
    // Read existing habits on app startup
    Provider.of<HabitDatabase>(context, listen: false).readhabits();
    super.initState();
  }

  void checkHabit(bool? value, Habit habit) {
    if (value != null) {
      context.read<HabitDatabase>().updateHabitCompletion(habit.id, value);
    }
  }

  void editHabit(Habit habit) {
    mycontroller.text = habit.name;
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                content: TextField(
                  controller: mycontroller,
                ),
                actions: [
                  MaterialButton(
                    onPressed: () {
                      String newHabitName = mycontroller.text;

                      // Save to db using isar
                      context
                          .read<HabitDatabase>()
                          .updateHabitName(habit.id, newHabitName);

                      Navigator.pop(context);

                      mycontroller.clear();
                    },
                    child: const Text("Save"),
                  ),
                  MaterialButton(
                    onPressed: () {
                      Navigator.pop(context);
                      mycontroller.clear();
                    },
                    child: const Text("Cancel"),
                  )
                ]));
  }

  void deleteHabit(Habit habit) {
    context.read<HabitDatabase>().deleteHabit(habit.id);
  }

  Future<List<dynamic>> geminiOutput(String newHabitName) async {
    final apiKey = dotenv.env['API_KEY'];
    final DateTime today = DateTime.now();
    final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey!,
        generationConfig:
            GenerationConfig(responseMimeType: 'application/json'));

    final prompt =
        '$newHabitName. Extract the date and activity from this text and output it using this JSON schema:\n'
        '[{"activity": activity , "date": DateTime}]\n'
        '$today, is the DateTime today'
        'Assume the date is in the current year if the year is not explicitly mentioned.'
        'Assume the date is in the current month if the month is not explicitly mentioned.'
        'tomorrow is the day after today'
        'the following week is the week after this week'
        'if no activity was mentioned, assume activity is error'
        'if date given is a period of time, return a List with dates throughout the period'
        'if there are multiple activities, return List containing the different activities';

    final response = await model.generateContent([Content.text(prompt)]);
    final jsonString = response.text;
    print(jsonString);
    final List<dynamic> data = jsonDecode(jsonString!);
    return data;
  }

  void createNewHabit() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                content: TextField(
                  controller: mycontroller,
                  decoration: InputDecoration(hintText: "Create a new Habit"),
                ),
                actions: [
                  MaterialButton(
                    onPressed: () async {
                      String text = mycontroller.text;

                      List<dynamic> raw_data = await geminiOutput(text);

                      for (int i = 0; i < raw_data.length; i++) {
                        String habitName = raw_data[i]['activity'];

                        DateTime date = DateTime.parse(raw_data[i]['date']);

                        context.read<HabitDatabase>().addHabit(habitName, date);
                      }
                      // Save to db using isar
                      Navigator.pop(context);

                      mycontroller.clear();
                    },
                    child: const Text("Save"),
                  ),
                  MaterialButton(
                    onPressed: () {
                      Navigator.pop(context);
                      mycontroller.clear();
                    },
                    child: const Text("Cancel"),
                  )
                ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: MyDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewHabit,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
      ),
      body: ListView(
        children: [
          _buildHeatMap(),
          _buildHabitList(),
        ],
      ),
    );
  }

  Widget _buildHeatMap() {
    final habitDatabase = context.watch<HabitDatabase>();
    List<Habit> currentHabits = habitDatabase.currentHabits;

    return FutureBuilder<DateTime?>(
      future: habitDatabase.getFirstLaunchDate(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return NewHeatMap(
            startDate: snapshot.data!,
            datasets: prepHeatMapDataset(currentHabits),
            onClick: (value) {
              setState(() {
                selectedDate = DateTime(value.year, value.month, value.day);
                print(selectedDate);
                // Store the clicked date
              });
            },
          );
        } else {
          return Container();
        }
      },
    );
  }

  Widget _buildHabitList() {
    final habitDatabase = context.watch<HabitDatabase>();
    List<Habit> currentHabits = habitDatabase.currentHabits;

    bool isSameDate(DateTime date1, DateTime date2) {
      return date1.year == date2.year &&
          date1.month == date2.month &&
          date1.day == date2.day;
    }

    // Filter habits based on the selected date
    List<Habit> filteredHabitsByDate(
        List<Habit> habits, DateTime? specificDate) {
      if (specificDate == null) return [];
      return habits
          .where((habit) => isSameDate(habit.createdDate, specificDate))
          .toList();
    }

    List<Habit> filteredHabits =
        filteredHabitsByDate(currentHabits, selectedDate);

    if (selectedDate == null || filteredHabits.isEmpty) {
      return Center(
        child: Text(
          selectedDate == null
              ? 'Select a date on the calendar to see habits'
              : 'No habits found for this date',
        ),
      );
    }

    // Return list of habits UI for the selected date
    return ListView.builder(
      itemCount: filteredHabits.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final habit = filteredHabits[index];
        bool isCompletedToday = isHabitCompletedToday(habit.completedDays);

        return HabitTile(
          iscompleted: isCompletedToday,
          text: habit.name,
          onChanged: (value) => checkHabit(value, habit),
          editHabit: (value) => editHabit(habit),
          deleteHabit: (value) => deleteHabit(habit),
        );
      },
    );
  }
}
