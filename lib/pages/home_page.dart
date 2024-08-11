import 'package:calendar/components/drawer.dart';
import 'package:calendar/components/habit_tile.dart';
import 'package:calendar/database/habit_database.dart';
import 'package:calendar/models/habit.dart';
import 'package:calendar/util/habit_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar/components/heatmap.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController mycontroller = TextEditingController();
  DateTime? selectedDate;

  void initState() {
    //read existing habits on app startup
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

                      // save to db using isar
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

  Future<Map<String, dynamic>> geminiOutput(String newHabitName) async {
    final apiKey = dotenv.env['API_KEY'];
    final DateTime today = DateTime.now();
    final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey!,
        generationConfig:
            GenerationConfig(responseMimeType: 'application/json'));

    final prompt =
        '$newHabitName. Extract the date and activity from this text and output it using this JSON schema:\n'
        '{"activity": activity , "date": DateTime}\n'
        '$today, is the DateTime today'
        'Assume the date is in the current year if the year is not explicitly mentioned.'
        'Assume the date is in the current month if the month is not explicitly mentioned.';
    final response = await model.generateContent([Content.text(prompt)]);
    final jsonString = response.text;
    final Map<String, dynamic> data = jsonDecode(jsonString!);
    return data;
  }

  void createNewHabit() async {
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

                      Map<String, dynamic> data = await geminiOutput(text);

                      String habitName = data['activity'];

                      DateTime date = data['date'];

                      // save to db using isar
                      context.read<HabitDatabase>().addHabit(habitName, date);

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
            )),
        body: ListView(
          children: [
            _buildHeatMap(),
            _buildHabitList(),
          ],
        ));
  }

  Widget _buildHeatMap() {
    final habitDatabase = context.watch<HabitDatabase>();

    List<Habit> currentHabits = habitDatabase.currentHabits;

    return FutureBuilder<DateTime?>(
      future: habitDatabase.getFirstLaunchDate(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MyHeatMap(
            startDate: snapshot.data!,
            datasets: prepHeatMapDataset(currentHabits),
            onClick: (value) {
              setState(() {
                selectedDate = value; // Set the selected date
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
    //habit db
    final habitDatabase = context.watch<HabitDatabase>();

    //current habits
    List<Habit> currentHabits = habitDatabase.currentHabits;

    // Filter habits based on the selected date
    List<Habit> filteredHabits = currentHabits.where((habit) {
      if (selectedDate == null) return false;
      return habit.completedDays.contains(selectedDate);
    }).toList();

    if (selectedDate == null || filteredHabits.isEmpty) {
      return Center(
        child: Text(
          selectedDate == null
              ? 'Select a date on the calendar to see habits'
              : 'No habits found for this date',
        ),
      );
    }

    //return list of habits UI
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
        });
  }
}
