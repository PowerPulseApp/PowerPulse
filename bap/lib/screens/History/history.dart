import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';


void main() {
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HistoryScreen(),
    );
  }
}


class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String? userId = user?.uid;


    return Scaffold(
      appBar: AppBar(
        title: Text('History',style: GoogleFonts.bebasNeue(
                  fontSize: 32,
                ),),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('workouts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final workouts = snapshot.data?.docs ?? [];
            return ListView.builder(
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                final workoutData =
                    workouts[index].data() as Map<String, dynamic>;
                final date = DateTime.parse(
                    workoutData['timestamp'].toDate().toString());
                final formattedDate = DateFormat('yyyy-MM-dd').format(date);
                final totalWorkoutTime =
                    _formatTime(workoutData['totalWorkoutTime']);
                return Dismissible(
                  key: Key(workouts[index].id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deleteWorkout(userId!, workouts[index].id);
                  },
                  child: Card(
                    margin: EdgeInsets.all(8.0),
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Date: $formattedDate'),
                            ],
                          ),
                          Text('Total Workout Time: $totalWorkoutTime'),
                          Text('Exercises:'),
                          for (var exercise in workoutData['exercises'])
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Exercise: ${exercise['name']}'),
                                ..._buildSetWidgets(exercise['sets']),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }


  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${_twoDigits(hours)}:${_twoDigits(minutes)}:${_twoDigits(remainingSeconds)}';
  }


  String _twoDigits(int n) {
    if (n >= 10) {
      return '$n';
    }
    return '0$n';
  }


  List<Widget> _buildSetWidgets(List<dynamic> sets) {
    return List.generate(
      sets.length,
      (index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Set ${index + 1}: Reps: ${sets[index]['reps']}, Weight: ${sets[index]['kg']} kg'),
            SizedBox(height: 4.0),
          ],
        );
      },
    );
  }


  Future<void> _deleteWorkout(String userId, String workoutId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .delete();
  }
}





