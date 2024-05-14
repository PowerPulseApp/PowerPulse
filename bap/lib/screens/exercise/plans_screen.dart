import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class PlansScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
     Color iconColor = Theme.of(context).iconTheme.color!;
    Color textColor = Theme.of(context).textTheme.bodyText2!.color!;
    return Scaffold(
      appBar: AppBar(
        title: Text('Plans List', style: TextStyle(color: textColor),),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('plans').snapshots(),
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
              final exerciseData = exercise.data() as Map<String, dynamic>;
              final exerciseName =
                  exerciseData['name'] ?? 'Plan Name Not Available';
              final exerciseDescription = exerciseData['description'] ?? 'No description available';
              final imageUrl = exerciseData['imageUrl'];
              return PlanTile(
                planName: exerciseName,
                imageUrl: imageUrl,
                exerciseDescription: exerciseDescription,
                onExerciseSelected: (selectedExercise) {
                  Navigator.pop(context, selectedExercise);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class PlanTile extends StatelessWidget {
  final String planName;
  final String? imageUrl;
  final String exerciseDescription;
  final Function(Map<String, dynamic>) onExerciseSelected;

  PlanTile({
    required this.planName,
    required this.imageUrl,
    required this.exerciseDescription,
    required this.onExerciseSelected,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDescription = exerciseDescription.replaceAll("\\n", "\n");

    return ListTile(
      title: Text(planName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.question_mark),
            onPressed: () {
              if (imageUrl != null) {
                _playExerciseVideo(context, imageUrl, formattedDescription);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              onExerciseSelected({'name': planName, 'description': formattedDescription});
            },
          ),
        ],
      ),
    );
  }

  void _playExerciseVideo(BuildContext context, String? videoUrl, String description) async {
    if (videoUrl != null) {
      final firebaseStorageRef =
          firebase_storage.FirebaseStorage.instance.refFromURL(videoUrl);
      String downloadURL = await firebaseStorageRef.getDownloadURL();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VideoPlayerScreen(downloadURL, description)),
      );
    }
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String imageUrl;
  final String description;

  VideoPlayerScreen(this.imageUrl, this.description);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  double _videoAspectRatio = 16 / 9; // Default aspect ratio
  double _sliderValue = 0.0; // Initial value for the slider

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(  
      widget.imageUrl,
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
    Color iconColor = Theme.of(context).iconTheme.color!;
    Color textColor = Theme.of(context).textTheme.bodyText2!.color!;
    return Scaffold(
      appBar: AppBar(
        title: Text('Info', style: TextStyle(color: textColor),),
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
                  Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover, // Adjust the fit as per your requirement
                  ),
                  SizedBox(height: 15),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(widget.description, style: TextStyle(fontSize: 16, color: textColor)),
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
    );
  }
}