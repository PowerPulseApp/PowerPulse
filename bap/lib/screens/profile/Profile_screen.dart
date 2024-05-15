import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bap/screens/login_screen/Login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key});


  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}


class _ProfileScreenState extends State<ProfileScreen> {
  late Stream<User?> _authStateStream; // Declare a stream to hold auth state
  File? _imageFile;


  @override
  void initState() {
    super.initState();
    _authStateStream =
        FirebaseAuth.instance.authStateChanges(); // Initialize the stream
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
                  backgroundImage: _imageFile != null
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
                    child: Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
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
    if (await _requestGalleryPermission()) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }


  Future<bool> _requestGalleryPermission() async {
    if (await Permission.photos.request().isGranted) {
      return true;
    } else {
      // If the user denies permission, show a dialog explaining why the permission is necessary
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text('Permission Required'),
          content: Text(
              'Please grant access to your photo gallery to change your profile picture.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Deny'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Allow'),
            ),
          ],
        ),
      );
      return false;
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





