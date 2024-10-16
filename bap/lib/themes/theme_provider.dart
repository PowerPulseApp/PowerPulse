import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _theme;

  ThemeData get theme => _theme;

  ThemeProvider() : _theme = ThemeData.light();

  void toggleTheme() {
    _theme = _theme == ThemeData.light()? ThemeData.dark() : ThemeData.light();
    notifyListeners();
  }
}
