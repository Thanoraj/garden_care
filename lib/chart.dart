import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';


class ChartPage extends StatefulWidget {
  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  final databaseReference = FirebaseDatabase.instance.reference();
  List<FlSpot> spots = [];
  List<String> times = []; // Store formatted times
  double index = 0;
  @override
  void initState() {
    super.initState();
    databaseReference.child('sensor-data').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {



          DateTime time = DateTime.now(); // Assuming key is in DateTime string format
          String formattedTime = DateFormat('HH:mm:ss').format(time);
          times.add(formattedTime);

          // Assuming 'sensor-data' is the key for the sensor value
          double sensorValue = (double.parse(data.toString().split(":")[1]) as num).toDouble();
          spots.add(FlSpot(index, sensorValue));
          index++;


        setState(() {
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final labelInterval = (times.length / 5).ceil();

    return Scaffold(
      appBar: AppBar(
        title: Text('Realtime Graph with Firebase'),
      ),
      body: spots.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
            padding: const EdgeInsets.only(bottom: 50.0,left: 10, right: 10, top: 10),
            child: LineChart(
        LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                // isCurved: true,
                colors: [Colors.blue],

                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false,),
              ),
            ],
            minY: 0,
            maxY: 100,
            titlesData: FlTitlesData(
              bottomTitles: SideTitles(
                showTitles: true,
                rotateAngle: -90,
                getTitles: (value) {
                  print(value);
                  // Format the index back to date string
                  return times[value.toInt()];
                },
              ),
              rightTitles: SideTitles(showTitles: false),
              topTitles: SideTitles(showTitles: false),
            ),
        ),
      ),
          ),
    );
  }
}