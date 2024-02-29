import 'package:bap/screens/profile/Profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bap/main.dart';
import 'package:bap/reusable_widgets/reusable_widget.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _userNameTextController = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();

  String _userNameError = '';
  String _emailError = '';
  String _passwordError = '';
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Sign Up",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 20,
                ),
                reusableTextField(
                    "Enter UserName",
                    Icons.person_outline,
                    false,
                    _userNameTextController,
                    _userNameError),
                const SizedBox(
                  height: 20,
                ),
                reusableTextField(
                    "Enter Email Id",
                    Icons.email_outlined,
                    false,
                    _emailTextController,
                    _emailError),
                const SizedBox(
                  height: 20,
                ),
                reusableTextField(
                    "Enter Password",
                    Icons.lock_outline,
                    true,
                    _passwordTextController,
                    _passwordError),
                const SizedBox(
                  height: 20,
                ),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                firebaseButton(context, "Sign Up", _signUp),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _signUp() async {
    String username = _userNameTextController.text.trim();
    String email = _emailTextController.text.trim();
    String password = _passwordTextController.text.trim();

    setState(() {
      _userNameError = username.isEmpty ? 'Username cannot be empty' : '';
      _emailError =
          email.isEmpty ? 'Email cannot be empty' : !isValidEmail(email) ? 'Invalid email format' : '';
      _passwordError = password.isEmpty ? 'Password cannot be empty' : password.length < 6 ? 'Password must be at least 6 characters long' : '';
      _errorMessage = '';
    });

    if (_userNameError.isEmpty && _emailError.isEmpty && _passwordError.isEmpty) {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email, password: password);
        print("Created New Account");
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => PowerPulseApp()));
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          setState(() {
            _errorMessage = 'Email is already in use';
          });
        } else {
          setState(() {
            _errorMessage = e.message ?? 'An error occurred';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred';
        });
      }
    }
  }

  bool isValidEmail(String email) {
    // You can implement your email validation logic here
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
