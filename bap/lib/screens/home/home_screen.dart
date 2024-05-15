import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';


class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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
    );
  }


  Future<String> _getCurrentUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // If the user is authenticated, fetch their username from Firestore
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();


        // Get the username from the document snapshot
        String username = userDoc.get('username');


        // Return the fetched username
        return username;
      } catch (e) {
        // If there's an error while fetching the username, return a default username
        print('Error fetching username: $e');
        return 'User';
      }
    } else {
      // If the user is not authenticated, return a default username
      return 'User';
    }
  }
}





