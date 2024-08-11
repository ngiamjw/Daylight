import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class MyHeatMap extends StatelessWidget {
  final DateTime startDate;
  final Map<DateTime, int> datasets;
  final Function(DateTime)? onClick;
  MyHeatMap(
      {super.key,
      required this.startDate,
      required this.datasets,
      required this.onClick});

  @override
  Widget build(BuildContext context) {
    return HeatMapCalendar(
        colorsets: const {
          1: Color.fromARGB(25, 47, 255, 0),
          2: Color.fromARGB(50, 47, 255, 0),
          3: Color.fromARGB(75, 47, 255, 0),
          4: Color.fromARGB(100, 47, 255, 0),
          5: Color.fromARGB(125, 47, 255, 0),
          6: Color.fromARGB(150, 47, 255, 0),
          7: Color.fromARGB(175, 47, 255, 0),
          8: Color.fromARGB(200, 47, 255, 0),
          9: Color.fromARGB(225, 47, 255, 0),
          10: Color.fromARGB(255, 47, 255, 0),
        },
        colorMode: ColorMode.color,
        defaultColor: Theme.of(context).colorScheme.secondary,
        textColor: Colors.white,
        showColorTip: false,
        size: 30,
        flexible: true,
        datasets: datasets,
        onClick: (value) {
          onClick!(value);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(value.toString())));
        });
  }
}
