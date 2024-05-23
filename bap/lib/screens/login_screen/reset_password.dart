import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bap/reusable_widgets/reusable_widget.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({Key? key}) : super(key: key);

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  TextEditingController _emailTextController = TextEditingController();
  String _emailError = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Reset Password",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 20,
                ),
                reusableTextField(
                  "Enter Email",
                  Icons.email_outlined,
                  false,
                  _emailTextController,
                  _emailError,
                ),
                const SizedBox(
                  height: 20,
                ),
                firebaseButton(context, "Reset Password", _resetPassword),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resetPassword() {
    String email = _emailTextController.text.trim();

    setState(() {
      _emailError = email.isEmpty ? 'Email cannot be empty' : '';
    });

    if (_emailError.isEmpty) {
      FirebaseAuth.instance.sendPasswordResetEmail(email: email)
          .then((value) => Navigator.of(context).pop());
    }
  }
}
