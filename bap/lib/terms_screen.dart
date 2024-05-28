import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfConditionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms of Conditions',
          style: GoogleFonts.bebasNeue(fontSize: 26),
        ),
      ),
      body: Center(
        child: Text('Terms of Conditions content goes here'),
      ),
    );
  }
}
