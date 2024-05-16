import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bap/screens/login_screen/Login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
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

  @override
  void initState() {
    super.initState();
    _authStateStream =
        FirebaseAuth.instance.authStateChanges(); // Initialize the stream
    _loadProfilePicture();
  }

  Future<void> _loadProfilePicture() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        _profilePictureUrl = userDoc.get('profilePicture');
      });
    } catch (e) {
      print('Error loading profile picture: $e');
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
                          : AssetImage('assets/pfp.jpg') as ImageProvider<Object>?,
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
                  return Text(
                    '${snapshot.data}',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
              }
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
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
      Reference storageReference = FirebaseStorage.instance.ref().child('profile_pictures/$uid.jpg');
      UploadTask uploadTask = storageReference.putFile(_imageFile!);
      await uploadTask.whenComplete(() async {
        String imageUrl = await storageReference.getDownloadURL();
        // Update the user's document in Firestore with the image URL
        await FirebaseFirestore.instance.collection('users').doc(uid).update({'profilePicture': imageUrl});
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
