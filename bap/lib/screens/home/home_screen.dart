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
            child: _buildPieChartWithLegend(),
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

  Widget _buildPieChartWithLegend() {
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
            print('Muscle Data: $muscleData');
            if (muscleData.isEmpty) {
              return Center(child: Text('No muscle workload data available'));
            }

            List<PieChartSectionData> sections =
                muscleData.entries.map((entry) {
              double percentage = (entry.value /
                      muscleData.values
                          .reduce((sum, element) => sum + element)) *
                  100;
              return PieChartSectionData(
                color: getColorForMuscle(entry.key),
                value: entry.value,
                title: '${percentage.toStringAsFixed(1)}%',
                radius: 60,
                titleStyle: TextStyle(fontSize: 12, color: Colors.white),
              );
            }).toList();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        borderData: FlBorderData(show: false),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: ListView(
                      children: muscleData.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                color: getColorForMuscle(entry.key),
                              ),
                              SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 12,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '(${entry.value.toStringAsFixed(1)} kg)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
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
        return Color.fromARGB(255, 106, 26, 131);
      case 'back':
        return Color.fromARGB(255, 18, 22, 235);
      case 'legs':
        return Color.fromARGB(255, 200, 0, 250);
      case 'arms':
        return Color.fromARGB(255, 200, 132, 255);
      case 'shoulders':
        return Color.fromARGB(255, 47, 0, 122);
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
              int reps = set['reps']; // Ensure reps is an int
              double weight =
                  (set['kg'] as num).toDouble(); // Ensure weight is a double
              totalWeight += (reps * weight);
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
          List<dynamic> exercises = workout.get('exercises');

          double totalWeight = 0;

          for (var exercise in exercises) {
            List<dynamic> sets = exercise['sets'];

            for (var set in sets) {
              int reps = set['reps'];
              double weight =
                  (set['kg'] as num).toDouble(); // Ensure weight is a double
              totalWeight += (reps * weight);
            }
          }

          totalWeight = totalWeight / 1000; // Convert to tons
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

        return userDoc.get('username');
      } catch (e) {
        print('Error fetching username: $e');
        return 'User';
      }
    } else {
      return 'User';
    }
  }
}
