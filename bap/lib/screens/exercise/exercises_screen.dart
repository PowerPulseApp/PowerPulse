import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:google_fonts/google_fonts.dart';

class ExercisesScreen extends StatefulWidget {
  @override
  _ExercisesScreenState createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  late TextEditingController _searchController;
  late Stream<QuerySnapshot> _exercisesStream;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _exercisesStream =
        FirebaseFirestore.instance.collection('exercises').snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Exercise List',
          style: GoogleFonts.bebasNeue(fontSize: 26),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Exercises...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                setState(() {
                  _exercisesStream = FirebaseFirestore.instance
                      .collection('exercises')
                      .where('name', isGreaterThanOrEqualTo: query)
                      .where('name',
                          isLessThan:
                              query + 'z') // Assuming alphabetical ordering
                      .snapshots();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _exercisesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                final exercises = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (BuildContext context, int index) {
                    final exercise = exercises[index];
                    final exerciseData =
                        exercise.data() as Map<String, dynamic>;
                    final exerciseName =
                        exerciseData['name'] ?? 'Exercise Name Not Available';
                    final videoUrl = exerciseData['videoUrl'];
                    final exerciseDescription = exerciseData['description'] ??
                        'No description available';
                    return ExerciseTile(
                      exerciseName: exerciseName,
                      videoUrl: videoUrl,
                      exerciseDescription: exerciseDescription,
                      onExerciseSelected: (selectedExercise) {
                        Navigator.pop(context, selectedExercise);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseTile extends StatelessWidget {
  final String exerciseName;
  final String? videoUrl;
  final String exerciseDescription;
  final Function(Map<String, dynamic>) onExerciseSelected;

  ExerciseTile({
    required this.exerciseName,
    required this.videoUrl,
    required this.exerciseDescription,
    required this.onExerciseSelected,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDescription = exerciseDescription.replaceAll("\\n", "\n");

    return ListTile(
      title: Text(exerciseName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.question_mark),
            onPressed: () {
              if (videoUrl != null) {
                _playExerciseVideo(context, videoUrl, formattedDescription);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              onExerciseSelected(
                  {'name': exerciseName, 'description': formattedDescription});
            },
          ),
        ],
      ),
    );
  }

  void _playExerciseVideo(
      BuildContext context, String? videoUrl, String description) async {
    if (videoUrl != null) {
      final firebaseStorageRef =
          firebase_storage.FirebaseStorage.instance.refFromURL(videoUrl);
      String downloadURL = await firebaseStorageRef.getDownloadURL();
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(downloadURL, description)),
      );
    }
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String description;

  VideoPlayerScreen(this.videoUrl, this.description);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  double _sliderValue = 0.0; // Initial value for the slider

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(
      widget.videoUrl,
    )..addListener(() {
        setState(() {
          _sliderValue = _controller.value.position.inSeconds.toDouble();
        });
      });
    _initializeVideoPlayerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Info',
          style: GoogleFonts.bebasNeue(fontSize: 26),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                    SizedBox(height: 15),
                    Slider(
                      value: _sliderValue,
                      min: 0,
                      max:
                          _controller.value.duration?.inSeconds.toDouble() ?? 0,
                      onChanged: (value) {
                        setState(() {
                          _sliderValue = value;
                          _controller.seekTo(Duration(seconds: value.toInt()));
                        });
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(widget.description,),
                    ),
                  ],
                ),
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
