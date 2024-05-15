import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart'; // Import the line chart widget

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
                // While the username is being fetched, display a loading indicator
                return Center(child: CircularProgressIndicator());
              } else {
                if (snapshot.hasError) {
                  // If an error occurs while fetching the username, display an error message
                  return Center(child: Text('Error fetching username'));
                } else {
                  // If the username is fetched successfully, display it
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
          SizedBox(height: 10), // Add some spacing between text and chart
          Expanded(
            child: _buildLineChart(), // Use a method to build the line chart
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
            return AspectRatio(
              aspectRatio: 2.0,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: 16,
                  left: 16,
                  top: 16,
                  bottom: 240,
                ),
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: snapshot.data!,
                        barWidth: 8,
                        isCurved: true,
                        curveSmoothness: 0.25,
                        preventCurveOverShooting: true,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                    titlesData: const FlTitlesData(
                      show: true,
                      leftTitles: AxisTitles(
                        axisNameWidget: Text('weight'),
                        axisNameSize: 25,
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: Text('workouts'),
                        axisNameSize: 25,
                      ),
                      rightTitles: AxisTitles(
                        axisNameWidget: Text('weight'),
                        axisNameSize: 25,
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
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

  Future<List<FlSpot>> _getWorkoutData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        QuerySnapshot workoutsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .orderBy('timestamp', descending: true)
            .limit(15)
            .get();

        List<FlSpot> spots = [];
        int index = 0;

        // Reverse the order of documents to display recent data on the right side
        List<QueryDocumentSnapshot> reversedWorkouts =
            workoutsSnapshot.docs.reversed.toList();

        for (QueryDocumentSnapshot workout in reversedWorkouts) {
          // Assuming the field name in Firestore is 'totalWeight'
          double totalWeight = workout.get('totalWeight');
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
