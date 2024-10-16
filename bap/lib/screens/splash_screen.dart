import 'package:bap/screens/login_screen/Login_screen.dart';
import 'package:flutter/material.dart';
import 'package:bap/reusable_widgets/reusable_widget.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  
    Future.delayed(Duration(seconds: 3), () {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => LoginScreen(),
    ));
  });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.black),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            logoWidget("assets/logo.png"),
          ],
        ),
        ),
    );
  }
}