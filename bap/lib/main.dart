import 'package:bap/ContactUs_screen.dart';
import 'package:flutter/material.dart';
import 'package:bap/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bap/screens/exercise/exercise_screen.dart';
import 'package:bap/screens/home/home_screen.dart';
import 'package:bap/screens/History/history.dart';
import 'package:bap/screens/groups/groups_screen.dart';
import 'package:bap/screens/profile/profile_screen.dart';
import 'package:bap/themes/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:bap/terms_screen.dart';

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
            home: SplashScreen(),
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
     Color selectedItemColor =
        Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: Padding(padding: const EdgeInsets.only(left: 14.0),child: Text('PP',style: GoogleFonts.blackOpsOne(fontSize: 27),),),
        actions: [
          IconButton(
            onPressed: () {
              _showSettingsMenu(context);
            },
            icon: Icon(Icons.settings),
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
        selectedItemColor: selectedItemColor,
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

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.brightness_4),
                title: Text('Change Theme'),
                onTap: () {
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                  Navigator.pop(context); // Close the bottom sheet after changing the theme
                },
              ),
              ListTile(
                leading: Icon(Icons.description),
                title: Text('Terms of Conditions'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _showTermsOfConditions(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.contact_mail),
                title: Text('Contact Us'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _launchEmailForm();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTermsOfConditions(BuildContext context) {
    // Show terms and conditions screen here
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TermsOfConditionsScreen(),
      ),
    );
  }

  void _launchEmailForm() async {
    Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => ContactUsScreen()),
  );
  }
}
