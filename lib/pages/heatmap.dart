import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class MyHeatMap extends StatelessWidget {
  const MyHeatMap({super.key});

  @override
  Widget build(BuildContext context) {
    return HeatMapCalendar(
      defaultColor: Colors.white,
      flexible: true,
      colorMode: ColorMode.color,
      datasets: {
        DateTime(2024, 8, 6): 3,
        DateTime(2021, 1, 7): 7,
        DateTime(2021, 1, 8): 10,
        DateTime(2021, 1, 9): 13,
        DateTime(2021, 1, 13): 6,
      },
      colorsets: const {
        1: Color.fromARGB(255, 47, 255, 0),
        2: Color.fromARGB(225, 47, 255, 0),
        3: Color.fromARGB(200, 47, 255, 0),
        4: Color.fromARGB(175, 47, 255, 0),
        5: Color.fromARGB(150, 47, 255, 0),
        6: Color.fromARGB(125, 47, 255, 0),
        7: Color.fromARGB(100, 47, 255, 0),
        8: Color.fromARGB(75, 47, 255, 0),
        9: Color.fromARGB(50, 47, 255, 0),
        10: Color.fromARGB(25, 47, 255, 0),
      },
      onClick: (value) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(value.toString())));
      },
    );
  }
}
