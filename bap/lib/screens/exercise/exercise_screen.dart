import 'package:flutter/material.dart';
import 'package:bap/reusable_widgets/reusable_widget.dart';
import 'package:bap/screens/exercise/new_plan_screen.dart';
import 'package:bap/screens/exercise/plans_screen.dart';
import 'package:bap/screens/exercise/new_workout_screen.dart';
import 'package:bap/main.dart'; // Import the new screen

class ExerciseScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Color iconAndTextColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LogoWidget(imagePath: "assets/eddie.png"),
                SizedBox(height: 8.0),
                _buildNavigationButton(
                    context, 'New Workout', NewWorkoutScreen()),
                SizedBox(height: 8.0),
                _buildNavigationButton(context, 'Plans', PlansScreen()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SizedBox(height: 64), // Add padding from the bottom
    );
  }

  Widget _buildNavigationButton(
      BuildContext context, String label, Widget destination) {
    ColorScheme currentColorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity, // Make button take full width
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 64.0), // Add padding from the sides
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SafeArea(child: destination), // Wrap with SafeArea
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            primary: currentColorScheme.onSurface.withOpacity(0.6),
            onPrimary: currentColorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 12.0), // Adjust vertical padding
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class LogoWidget extends StatelessWidget {
  final String imagePath;

  const LogoWidget({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color logoColor =
        Theme.of(context).primaryColor; // Get color from the theme

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.asset(
        imagePath,
        color: logoColor, // Set the color dynamically
        width: 300, // Adjust size as needed
        height: 300,
      ),
    );
  }
}
