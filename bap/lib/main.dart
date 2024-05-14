import 'package:bap/reusable_widgets/reusable_widget.dart';
import 'package:bap/screens/login_screen/Login_screen.dart';
import 'package:bap/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:bap/screens/exercise/exercise_screen.dart';
import 'package:bap/screens/home/home_screen.dart';
import 'package:bap/screens/History/history.dart';
import 'package:bap/screens/groups/groups_screen.dart';
import 'package:bap/screens/profile/profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bap/themes/theme_provider.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'PowerPulse',
            theme: themeProvider.theme,
            home: PowerPulseApp(),
          );
        },
      ),
    );
  }
}

class PowerPulseApp extends StatefulWidget {
  @override
  _PowerPulseAppState createState() => _PowerPulseAppState();
}

class _PowerPulseAppState extends State<PowerPulseApp> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    HistoryScreen(),
    ExerciseScreen(),
    GroupsScreen(),
    ProfileScreen(),
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: Container(padding: EdgeInsets.all(0), child: Image.asset('assets/logo.png'),),
        actions: [
          IconButton(
            onPressed: () {
              print('Toggle theme button pressed');
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            icon: Icon(Icons.brightness_4),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          child: _pages[_selectedIndex],
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Exercise',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
