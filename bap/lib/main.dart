import 'package:bap/screens/login_screen/Login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:bap/screens/exercise/exercise_screen.dart';
import 'package:bap/screens/home/home_screen.dart';
import 'package:bap/screens/History/history.dart';
import 'package:bap/screens/groups/groups_screen.dart';
import 'package:bap/screens/profile/profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp();
  runApp(const MyApp());
}

bool _iconBool = false;

IconData _iconLight = Icons.wb_sunny;
IconData _iconDark = Icons.nights_stay;

ColorScheme _lightColorScheme = ColorScheme(
  primary: const Color.fromARGB(255, 0, 140, 255),
  secondary: Color.fromARGB(255, 182, 183, 184),
  surface: Color.fromARGB(255, 182, 183, 184),
  background: Color.fromARGB(255, 182, 183, 184),
  error: Color.fromARGB(255, 182, 183, 184),
  onPrimary: Color.fromARGB(255, 182, 183, 184),
  onSecondary: Color.fromARGB(255, 182, 183, 184),
  onSurface: Color.fromARGB(255, 50, 50, 50),
  onBackground: Color.fromARGB(255, 182, 183, 184),
  onError: Color.fromARGB(255, 182, 183, 184),
  brightness: Brightness.light,
);

ColorScheme _darkColorScheme = ColorScheme(
  primary: Color.fromARGB(255, 255, 0, 0),
  secondary: Color.fromARGB(255, 50, 50, 50),
  surface: Color.fromARGB(255, 50, 50, 50),
  background: Color.fromARGB(255, 50, 50, 50),
  error: Color.fromARGB(255, 50, 50, 50),
  onPrimary: Color.fromARGB(255, 50, 50, 50),
  onSecondary: Color.fromARGB(255, 50, 50, 50),
  onSurface: Color.fromARGB(255, 182, 183, 184),
  onBackground: Color.fromARGB(255, 50, 50, 50),
  onError: Color.fromARGB(255, 50, 50, 50),
  brightness: Brightness.dark,
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
 Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PowerPulse',
      home: LoginScreen(),
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
    ColorScheme currentColorScheme = _getCurrentColorScheme();

    return MaterialApp(
      theme: ThemeData(
        primaryColor: currentColorScheme.primary,
        hintColor: currentColorScheme.secondary,
        scaffoldBackgroundColor: currentColorScheme.background,
      ),
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(
            'PP',
            style: GoogleFonts.blackOpsOne(
              color: _iconBool
                  ? Color.fromARGB(255, 255, 17, 0)
                  : Colors.blue,
              fontSize: 40.0,
            ),
          ),
          backgroundColor: currentColorScheme.background,
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  _iconBool = !_iconBool;
                });
                _scaffoldKey.currentState?.setState(() {});
              },
              icon: Icon(_iconBool ? _iconDark : _iconLight),
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
          backgroundColor: currentColorScheme.background,
          selectedItemColor: _iconBool ? _darkColorScheme.primary : Colors.blue,
          unselectedItemColor: _iconBool
              ? _darkColorScheme.onSurface.withOpacity(0.6)
              : _lightColorScheme.onSurface.withOpacity(0.6),
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
      ),
    );
  }

  ColorScheme _getCurrentColorScheme() {
    return _iconBool ? _darkColorScheme : _lightColorScheme;
  }
}
