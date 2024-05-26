import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class OtherProfileScreen extends StatefulWidget {
  final String userId;

  const OtherProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
  String? _profilePictureUrl;
  String? _bio;
  DateTime? _creationDate;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    _loadBio();
    _loadCreationDate();
  }

  Future<void> _loadProfilePicture() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      setState(() {
        _profilePictureUrl = userDoc.get('profilePicture');
      });
    } catch (e) {
      print('Error loading profile picture: $e');
    }
  }

  Future<void> _loadBio() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      setState(() {
        _bio = userDoc.get('bio');
      });
    } catch (e) {
      print('Error loading bio: $e');
    }
  }

  Future<void> _loadCreationDate() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      setState(() {
        _creationDate = userDoc.get('creationDate').toDate();
      });
    } catch (e) {
      print('Error loading creation date: $e');
    }
  }

  Future<double> _calculateTotalWeightLifted() async {
    try {
      final workoutSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('workouts')
          .get();

      double totalWeight = 0;
      for (var doc in workoutSnapshot.docs) {
        totalWeight += doc.get('totalWeight');
      }
      return totalWeight / 1000; // Convert kg to tons
    } catch (e) {
      print('Error calculating total weight lifted: $e');
      return 0;
    }
  }

  Future<double> _calculateTotalWorkoutTime() async {
    try {
      final workoutSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('workouts')
          .get();

      double totalTime = 0;
      for (var doc in workoutSnapshot.docs) {
        totalTime += doc.get('totalWorkoutTime');
      }
      return totalTime / 60.0 / 60.0; // Convert minutes to hours
    } catch (e) {
      print('Error calculating total workout time: $e');
      return 0;
    }
  }

  Future<int> _calculateTotalWorkouts() async {
    try {
      final workoutSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('workouts')
          .get();

      // Return the total number of documents (workouts) in the collection
      return workoutSnapshot.size;
    } catch (e) {
      print('Error calculating total workouts: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.bebasNeue(),
        ),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundImage: _profilePictureUrl != null
                  ? NetworkImage(_profilePictureUrl!)
                  : AssetImage('assets/pfp.jpg') as ImageProvider<Object>?,
            ),
            SizedBox(height: 10),
            FutureBuilder<String>(
              future: _getCurrentUsername(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else {
                  if (snapshot.hasError) {
                    return Text('User');
                  } else {
                    return Column(
                      children: [
                        Text(
                          '${snapshot.data}',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          _bio ?? 'No bio available',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        if (_creationDate != null)
                          Text(
                            'Member since: ${_creationDate!.toLocal().toString().split(' ')[0]}',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        SizedBox(height: 20),
                        FutureBuilder<List>(
                          future: Future.wait([
                            _calculateTotalWeightLifted(),
                            _calculateTotalWorkoutTime(),
                            _calculateTotalWorkouts()
                          ]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else {
                              if (snapshot.hasError) {
                                return Text('Error calculating workout data');
                              } else {
                                double totalWeightLifted =
                                    snapshot.data?[0] ?? 0;
                                double totalWorkoutTime =
                                    snapshot.data?[1] ?? 0;
                                int totalWorkouts = snapshot.data?[2] ?? 0;
                                return DataTable(
                                  columns: [
                                    DataColumn(label: Text('')),
                                    DataColumn(label: Text('')),
                                  ],
                                  rows: [
                                    DataRow(cells: [
                                      DataCell(Text('Total Workouts')),
                                      DataCell(Text(totalWorkouts.toString())),
                                    ]),
                                    DataRow(cells: [
                                      DataCell(Text('Overall workout time')),
                                      DataCell(Text(
                                          '${totalWorkoutTime.toStringAsFixed(2)} hours')),
                                    ]),
                                    DataRow(cells: [
                                      DataCell(Text('Weight lifted overall')),
                                      DataCell(Text(
                                          '${totalWeightLifted.toStringAsFixed(2)} tons')),
                                    ]),
                                  ],
                                );
                              }
                            }
                          },
                        ),
                      ],
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getCurrentUsername(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      String username = userDoc.get('username');
      return username;
    } catch (e) {
      print('Error fetching username: $e');
      throw e;
    }
  }
}
