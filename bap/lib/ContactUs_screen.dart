import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ContactUsScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _problemController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contact Us',
          style: GoogleFonts.bebasNeue(fontSize: 26),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _problemController,
              decoration: InputDecoration(
                labelText: 'Describe your problem',
              ),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _sendToFirestore(context);
              },
              child: Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendToFirestore(BuildContext context) {
    final String email = _emailController.text.trim();
    final String problem = _problemController.text.trim();

    if (email.isNotEmpty && problem.isNotEmpty) {
      FirebaseFirestore.instance.collection('feedback').add({
        'email': email,
        'problem': problem,
        'timestamp': DateTime.now(),
      }).then((value) {
        // Clear text fields after sending
        _emailController.clear();
        _problemController.clear();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feedback sent successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }).catchError((error) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send feedback. Please try again later.'),
            duration: Duration(seconds: 2),
          ),
        );
      });
    } else {
      // Show error message if email or problem is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill out all fields.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
