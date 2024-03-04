import 'package:bap/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bap/screens/profile/Profile_screen.dart';
import 'package:bap/screens/login_screen/reset_password.dart';
import 'package:bap/screens/login_screen/signup_screen.dart';
import 'package:bap/reusable_widgets/reusable_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();

  String _emailError = '';
  String _passwordError = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).size.height * 0.2, 20, 0),
            child: Column(
              children: <Widget>[
                logoWidget("assets/logo.png"),
                SizedBox(height: 30),
                reusableTextField(
                  "Enter Email",
                  Icons.person_outline,
                  false,
                  _emailTextController,
                  _emailError,
                ),
                SizedBox(height: 20),
                reusableTextField(
                  "Enter Password",
                  Icons.lock_outline,
                  true,
                  _passwordTextController,
                  _passwordError,
                ),
                SizedBox(height: 3),
                forgetPassword(context),
                if (_emailError.isNotEmpty || _passwordError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _emailError.isNotEmpty ? _emailError : _passwordError,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                firebaseButton(context, "Log IN", _signIn),
                signUpOption(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _signIn() async {
    String email = _emailTextController.text.trim();
    String password = _passwordTextController.text.trim();

    setState(() {
      _emailError = email.isEmpty ? 'Email cannot be empty' : '';
      _passwordError = password.isEmpty ? 'Password cannot be empty' : '';
    });

    if (_emailError.isEmpty && _passwordError.isEmpty) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        // Navigate to next screen upon successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PowerPulseApp()),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          setState(() {
            _emailError = 'Invalid login information';
            _passwordError = 'Invalid login information';
          });
        } else if (e.code == 'invalid-verification-code') {
          setState(() {
            _emailError = 'Invalid login information';
            _passwordError = 'Invalid login information';
            // Handle the specific case of empty reCAPTCHA token
            _passwordError = 'Empty reCAPTCHA token';
          });
        }
      } catch (e) {
        print(e);
        // Handle other exceptions if any
      }
    } else {
      // Call setState to trigger UI rebuild to display error messages
      setState(() {});
    }
  }

  Widget signUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? ",
            style: TextStyle(color: Color.fromARGB(179, 0, 0, 0))),
        GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => SignUpScreen()));
          },
          child: const Text(
            "Sign Up",
            style: TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  Widget forgetPassword(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 35,
      alignment: Alignment.bottomRight,
      child: TextButton(
        child: Text(
          "Forgot Password?",
          style: TextStyle(color: Colors.black),
          textAlign: TextAlign.right,
        ),
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => ResetPassword())),
      ),
    );
  }
}
