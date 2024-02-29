import 'package:flutter/material.dart';

class StrengthScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text('This is the strength screen.'),
              ),
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(70.0),
              child: ElevatedButton(
                onPressed: () {
                  // Add your logic for adding exercise here
                },
                child: Text('Add Exercise'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
