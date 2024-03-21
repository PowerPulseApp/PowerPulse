import 'package:flutter/material.dart';
import 'dart:async';
import 'exercises_screen.dart';

class NewWorkoutScreen extends StatefulWidget {
  @override
  _NewWorkoutScreenState createState() => _NewWorkoutScreenState();
}

class _NewWorkoutScreenState extends State<NewWorkoutScreen> {
  late Timer _timer;
  int _secondsElapsed = 0;
  bool _isPaused = false;
  List<Map<String, dynamic>> selectedExercises = [];

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

  Future<Map<String, dynamic>?> _addSet(BuildContext context) async {
    TextEditingController kgController = TextEditingController();
    TextEditingController repsController = TextEditingController();

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Set'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: kgController,
                decoration: InputDecoration(labelText: 'Kg'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: repsController,
                decoration: InputDecoration(labelText: 'Reps'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'kg': double.tryParse(kgController.text) ?? 0.0,
                  'reps': int.tryParse(repsController.text) ?? 0,
                });
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _deleteSet(int exerciseIndex, int setIndex) {
    setState(() {
      selectedExercises[exerciseIndex]['sets'].removeAt(setIndex);
    });
  }

  void _deleteExercise(int index) {
    setState(() {
      selectedExercises.removeAt(index);
    });
  }

  void _finishWorkout() {
    // Handle finishing workout here
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
            TextButton(
              onPressed: _finishWorkout,
              child: Text(
                'Finish Workout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: selectedExercises.length,
          itemBuilder: (context, exerciseIndex) {
            final exercise = selectedExercises[exerciseIndex];
            return Dismissible(
              key: Key(exercise['name']),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20.0),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              onDismissed: (direction) {
                _deleteExercise(exerciseIndex);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(exercise['name']),
                    subtitle: Text('Sets: ${exercise['sets'].length}'),
                    trailing: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () async {
                        final set = await _addSet(context);
                        if (set != null) {
                          setState(() {
                            selectedExercises[exerciseIndex]['sets'].add(set);
                          });
                        }
                      },
                    ),
                  ),
                  if (exercise['sets'].isNotEmpty)
                    Column(
                      children: [
                        for (var setIndex = 0; setIndex < exercise['sets'].length; setIndex++)
                          ListTile(
                            title: Text('Kg: ${exercise['sets'][setIndex]['kg']}, Reps: ${exercise['sets'][setIndex]['reps']}'),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteSet(exerciseIndex, setIndex),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final selectedExercise = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ExercisesScreen()),
            );
            // Handle the selected exercise data here
            if (selectedExercise != null) {
              selectedExercises.add({...selectedExercise, 'sets': []});
              setState(() {});
            }
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
