import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FutureBuilder(
            future: _getCurrentUsername(),
            builder: (context, AsyncSnapshot<String> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else {
                if (snapshot.hasError) {
                  return Center(child: Text('Error fetching username'));
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Hello ${snapshot.data}!',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 32,
                      ),
                    ),
                  );
                }
              }
            },
          ),
          SizedBox(height: 10),
          Expanded(
            child: _buildLineChart(),
          ),
          SizedBox(height: 10),
          Expanded(
            child: _buildPieChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return FutureBuilder<List<FlSpot>>(
      future: _getWorkoutData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading data'));
          } else {
            List<FlSpot> spots = snapshot.data ?? [];
            double maxWeight = spots.isNotEmpty
                ? spots
                    .map((spot) => spot.y)
                    .reduce((max, value) => value > max ? value : max)
                : 0;

            double maxY = (maxWeight * 1.166).ceilToDouble();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      barWidth: 5,
                      isCurved: true,
                      curveSmoothness: 0.25,
                      preventCurveOverShooting: true,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Color.fromARGB(90, 135, 70, 146),
                      ),
                      color: Color.fromARGB(255, 135, 70, 146),
                    ),
                  ],
                  titlesData: const FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      axisNameWidget: Text('weight in tons'),
                      axisNameSize: 25,
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text('workouts'),
                      axisNameSize: 25,
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                      ),
                    ),
                    topTitles: AxisTitles(
                      axisNameWidget:
                          Text('Total weight over the last 30 workouts'),
                      axisNameSize: 25,
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  minY: 0,
                  maxY: maxY,
                  clipData: FlClipData.all(),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      width: 3,
                    ),
                  ),
                ),
              ),
            );
          }
        }
      },
    );
  }

  Widget _buildPieChart() {
    return FutureBuilder<Map<String, double>>(
      future: _getMuscleWorkload(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading data: ${snapshot.error}'));
          } else {
            Map<String, double> muscleData = snapshot.data ?? {};
            print('Muscle Data: $muscleData'); // Add this line for logging
            if (muscleData.isEmpty) {
              return Center(child: Text('No muscle workload data available'));
            }

            List<PieChartSectionData> sections =
                muscleData.entries.map((entry) {
              return PieChartSectionData(
                color: getColorForMuscle(entry.key),
                value: entry.value,
                title:
                    '${((entry.value / muscleData.values.reduce((a, b) => a + b)) * 100).toStringAsFixed(1)}%',
                radius: 60,
                titleStyle: TextStyle(fontSize: 16, color: Colors.white),
              );
            }).toList();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: PieChart(
                PieChartData(
                  sections: sections,
                  borderData: FlBorderData(show: false),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            );
          }
        }
      },
    );
  }

  Color getColorForMuscle(String muscle) {
    switch (muscle) {
      case 'chest':
        return Colors.red;
      case 'back':
        return Colors.green;
      case 'legs':
        return Colors.blue;
      case 'arms':
        return Colors.yellow;
      case 'shoulders':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<Map<String, double>> _getMuscleWorkload() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        QuerySnapshot workoutsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .get();

        Map<String, double> muscleWorkload = {};

        for (QueryDocumentSnapshot workout in workoutsSnapshot.docs) {
          List<dynamic> exercises = workout.get('exercises');

          for (var exercise in exercises) {
            String name = exercise['name'];
            List<dynamic> sets = exercise['sets'];

            double totalWeight = 0;
            for (var set in sets) {
              double reps = set['reps'];
              double weight = set['kg'];
              totalWeight += reps * weight;
            }

            String muscle = await _getMuscleForExercise(name);
            print(
                'Exercise: $name, Muscle: $muscle, TotalWeight: $totalWeight');
            if (muscle.isNotEmpty) {
              if (muscleWorkload.containsKey(muscle)) {
                muscleWorkload[muscle] =
                    (muscleWorkload[muscle] ?? 0) + totalWeight;
              } else {
                muscleWorkload[muscle] = totalWeight;
              }
            }
          }
        }

        print('Muscle Workload: $muscleWorkload'); // Added print statement
        return muscleWorkload;
      } catch (e) {
        print('Error fetching muscle workload: $e');
        return {};
      }
    } else {
      return {};
    }
  }

  Future<String> _getMuscleForExercise(String name) async {
    try {
      DocumentSnapshot exerciseDoc = await FirebaseFirestore.instance
          .collection('exercises')
          .doc(name)
          .get();

      if (exerciseDoc.exists) {
        return exerciseDoc.get('muscle').toString().toLowerCase();
      } else {
        print('No muscle found for exercise: $name');
        return '';
      }
    } catch (e) {
      print('Error fetching muscle for exercise $name: $e');
      return '';
    }
  }

  Future<List<FlSpot>> _getWorkoutData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        QuerySnapshot workoutsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .orderBy('timestamp', descending: true)
            .limit(30)
            .get();

        List<FlSpot> spots = [];
        int index = 0;

        List<QueryDocumentSnapshot> reversedWorkouts =
            workoutsSnapshot.docs.reversed.toList();

        for (QueryDocumentSnapshot workout in reversedWorkouts) {
          double totalWeight = workout.get('totalWeight') / 1000;
          spots.add(FlSpot(index.toDouble(), totalWeight));
          index++;
        }
        return spots;
      } catch (e) {
        print('Error fetching workout data: $e');
        return [];
      }
    } else {
      return [];
    }
  }

  Future<String> _getCurrentUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        String username = userDoc.get('username');
        return username;
      } catch (e) {
        print('Error fetching username: $e');
        return 'User';
      }
    } else {
      return 'User';
    }
  }
}
