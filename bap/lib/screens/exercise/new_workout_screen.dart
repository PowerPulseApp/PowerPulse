import 'package:flutter/material.dart';
import 'dart:async';

class NewWorkoutScreen extends StatefulWidget {
  @override
  _NewWorkoutScreenState createState() => _NewWorkoutScreenState();
}

class _NewWorkoutScreenState extends State<NewWorkoutScreen> {
  late Timer _timer;
  int _secondsElapsed = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), _incrementTimer);
  }

  void _incrementTimer(Timer timer) {
    if (!_isPaused) {
      setState(() {
        _secondsElapsed++;
      });
    }
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${_twoDigits(hours)}:${_twoDigits(minutes)}:${_twoDigits(remainingSeconds)}';
  }

  String _twoDigits(int n) {
    if (n >= 10) {
      return '$n';
    }
    return '0$n';
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('End workout?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('No'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Yes'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _confirmLeave(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () async {
              bool confirm = await _confirmLeave(context);
              if (confirm) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(_formatTime(_secondsElapsed)),
          actions: [
            IconButton(
              onPressed: _togglePause,
              icon: _isPaused ? Icon(Icons.play_arrow) : Icon(Icons.pause),
            ),
          ],
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              // Add your logic here
              print('Add Exercise button pressed');
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: Text('+ Exercise'),
          ),
        ),
      ),
    );
  }
}
