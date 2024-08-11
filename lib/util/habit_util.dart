//given a habit list of completion days
//is the habit completed today
import 'package:calendar/models/habit.dart';

bool isHabitCompletedToday(List<DateTime> completedDays) {
  return completedDays.isNotEmpty;
}

//prepare heat map dataset
Map<DateTime, int> prepHeatMapDataset(List<Habit> habits) {
  Map<DateTime, int> dataset = {};

  for (var habit in habits) {
    for (var date in habit.completedDays) {
      print(habit.completedDays);
      final norminalisedDate = DateTime(date.year, date.month, date.day);

      if (dataset.containsKey(norminalisedDate)) {
        dataset[norminalisedDate] = dataset[norminalisedDate]! + 1;
      } else {
        dataset[norminalisedDate] = 1;
      }
    }
  }
  print(dataset);
  return dataset;
}
