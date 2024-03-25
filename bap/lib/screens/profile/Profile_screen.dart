import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bap/screens/login_screen/Login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Stream<User?> _authStateStream; // Declare a stream to hold auth state

  @override
  void initState() {
    super.initState();
    _authStateStream =
        FirebaseAuth.instance.authStateChanges(); // Initialize the stream
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
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
            return buildProfileWidget();
          }
        } else {
          // Connection state is not active yet
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget buildProfileWidget() {
    return Center(
      child: ElevatedButton(
        child: Text("Logout"),
        onPressed: () {
          FirebaseAuth.instance.signOut().then((value) {
            print("Signed Out");
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => LoginScreen()));
          }).catchError((error) {
            print("Sign out failed: $error");
          });
        },
      ),
    );
  }
}
