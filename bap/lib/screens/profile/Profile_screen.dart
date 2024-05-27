import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bap/screens/login_screen/Login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import FirebaseStorage

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Stream<User?> _authStateStream; // Declare a stream to hold auth state
  File? _imageFile;
  String? _profilePictureUrl;
  String? _bio;
  DateTime? _creationDate;
  TextEditingController _bioController =
      TextEditingController(); // Controller for bio input
  bool _isEditingBio = false;
// List to hold group members

  @override
  void initState() {
    super.initState();
    _authStateStream =
        FirebaseAuth.instance.authStateChanges(); // Initialize the stream
    _loadProfilePicture();
    _loadBio();
    _loadCreationDate();
  }

  Future<void> _loadProfilePicture() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        _profilePictureUrl = userDoc.get('profilePicture');
      });
    } catch (e) {
      print('Error loading profile picture: $e');
    }
  }

  Future<void> _loadBio() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        _bio = userDoc.get('bio');
      });
    } catch (e) {
      print('Error loading bio: $e');
    }
  }

  Future<void> _loadCreationDate() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      setState(() {
        _creationDate = user?.metadata.creationTime;
      });
    } catch (e) {
      print('Error loading creation date: $e');
    }
  }

  Future<double> _calculateTotalWeightLifted() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final workoutSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
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
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final workoutSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('workouts')
          .get();

      double totalTime = 0;
      for (var doc in workoutSnapshot.docs) {
        totalTime += doc.get('totalWorkoutTime');
      }
      return totalTime / 60.0 / 60.0;
    } catch (e) {
      print('Error calculating total workout time: $e');
      return 0;
    }
  }

  Future<int> _calculateTotalWorkouts() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final workoutSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('workouts')
          .get();

      // Return the total number of documents (workouts) in the collection
      return workoutSnapshot.size;
    } catch (e) {
      print('Error calculating total workouts: $e');
      return 0;
    }
  }

  Future<void> _removeMember(String memberId) async {
    try {
      String groupId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .update({
        'members': FieldValue.arrayRemove([
          {'uid': memberId}
        ])
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Member removed successfully')));
    } catch (e) {
      print('Error removing member: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to remove member')));
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
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: _authStateStream,
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            User? user = snapshot.data;
            if (user == null) {
              // User is signed out
              return Center(
                child: Text("User is currently signed out!"),
              );
            } else {
              // User is signed in
              return buildProfileWidget(user);
            }
          } else {
            // Connection state is not active yet
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  Widget buildProfileWidget(User user) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          GestureDetector(
            onTap: _changeProfilePicture,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _profilePictureUrl != null
                      ? NetworkImage(_profilePictureUrl!)
                      : _imageFile != null
                          ? FileImage(_imageFile!)
                          : AssetImage('assets/pfp.jpg')
                              as ImageProvider<Object>?,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.all(4),
                    child: GestureDetector(
                      onTap: _changeProfilePicture,
                      child: Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          FutureBuilder<String>(
            future: _getCurrentUsername(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // While the username is being fetched, display a loading indicator
                return CircularProgressIndicator();
              } else {
                if (snapshot.hasError) {
                  // If an error occurs while fetching the username, display a default username
                  return Text('User');
                } else {
                  // If the username is fetched successfully, display it
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
                      // Display bio as text or text field based on editing state
                      Row(
                        children: [
                          IconButton(
                            onPressed:
                                () {}, // This button is transparent and inactive
                            icon: Icon(Icons.edit, color: Colors.transparent),
                          ),
                          Expanded(
                            child: _isEditingBio
                                ? _buildEditableBioWidget()
                                : _buildNonEditableBioWidget(),
                          ),
                          IconButton(
                            onPressed:
                                _isEditingBio ? _saveBio : _startEditingBio,
                            icon: Icon(_isEditingBio ? Icons.save : Icons.edit),
                          ),
                        ],
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
                      FutureBuilder<List<dynamic>>(
                        future: Future.wait([
                          _calculateTotalWeightLifted(),
                          _calculateTotalWorkoutTime(),
                          _calculateTotalWorkouts(),
                        ]),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            // While the data is being fetched, display a loading indicator
                            return CircularProgressIndicator();
                          } else {
                            if (snapshot.hasError) {
                              // If an error occurs while fetching the data, display an error message
                              return Text('Error calculating workout data');
                            } else {
                              double totalWeightLifted = snapshot.data?[0] ?? 0;
                              double totalWorkoutTime = snapshot.data?[1] ?? 0;
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
    );
  }

  Widget _buildNonEditableBioWidget() {
    return Column(
      children: [
        Text(
          _bio ?? 'No bio available',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildEditableBioWidget() {
    return TextFormField(
      controller: _bioController,
      decoration: InputDecoration(
        hintText: 'Enter your bio',
        border: OutlineInputBorder(),
      ),
      maxLines: null,
    );
  }

  void _startEditingBio() {
    setState(() {
      _isEditingBio = true;
      _bioController.text = _bio ?? '';
    });
  }

  void _saveBio() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'bio': _bioController.text});
      setState(() {
        _bio = _bioController.text;
        _isEditingBio = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Bio updated successfully')));
    } catch (e) {
      print('Error updating bio: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update bio')));
    }
  }

  void _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadProfilePicture();
    }
  }

  Future<void> _uploadProfilePicture() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      Reference storageReference =
          FirebaseStorage.instance.ref().child('profile_pictures/$uid.jpg');
      UploadTask uploadTask = storageReference.putFile(_imageFile!);
      await uploadTask.whenComplete(() async {
        String imageUrl = await storageReference.getDownloadURL();
        // Update the user's document in Firestore with the image URL
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'profilePicture': imageUrl});
      });
    } catch (e) {
      print('Error uploading profile picture: $e');
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to log out?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              FirebaseAuth.instance.signOut().then((value) {
                print("Signed Out");
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginScreen()));
              }).catchError((error) {
                print("Sign out failed: $error");
              });
              Navigator.pop(context); // Close the dialog
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<String> _getCurrentUsername(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      // Get the username from the document snapshot
      String username = userDoc.get('username');

      // Return the fetched username
      return username;
    } catch (e) {
      print('Error fetching username: $e');
      throw e;
    }
  }
}
