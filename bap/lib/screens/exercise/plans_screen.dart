import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class PlansScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Color textColor = Theme.of(context).textTheme.bodyText2!.color!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Plans List',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('plans').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final plans = snapshot.data!.docs;
          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (BuildContext context, int index) {
              final plan = plans[index];
              final planData = plan.data() as Map<String, dynamic>;
              final planName = planData['name'] ?? 'Plan Name Not Available';
              return PlanTile(
                planName: planName,
                onPlanSelected: (selectedPlan) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlanDetailsScreen(planName: planName),
                    ),
                  );
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
  final Function(String) onPlanSelected;

  PlanTile({
    required this.planName,
    required this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(planName),
      trailing: IconButton(
        icon: Icon(Icons.arrow_forward),
        onPressed: () {
          onPlanSelected(planName);
        },
      ),
    );
  }
}

class PlanDetailsScreen extends StatelessWidget {
  final String planName;

  PlanDetailsScreen({required this.planName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(planName),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('plans').doc(planName).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final planData = snapshot.data!.data() as Map<String, dynamic>?;
          if (planData == null) {
            return Center(child: Text('Plan data not available'));
          }
          final exercisesList = planData['exercises'] as List<dynamic>? ?? [];
          return ListView.builder(
            itemCount: exercisesList.length,
            itemBuilder: (BuildContext context, int index) {
              final exerciseId = exercisesList[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('exercises').doc(exerciseId).get(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }
                  final exerciseData = snapshot.data!.data() as Map<String, dynamic>;
                  final exerciseName = exerciseData['name'] ?? 'Exercise Name Not Available';
                  final exerciseDescription = exerciseData['description'] ?? 'No description available';
                  final imageUrl = exerciseData['imageUrl'];
                  return ExerciseTile(
                    exerciseName: exerciseName,
                    exerciseDescription: exerciseDescription,
                    imageUrl: imageUrl,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ExerciseTile extends StatelessWidget {
  final String exerciseName;
  final String exerciseDescription;
  final String? imageUrl;

  ExerciseTile({
    required this.exerciseName,
    required this.exerciseDescription,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDescription = exerciseDescription.replaceAll("\\n", "\n");

    return ListTile(
      title: Text(exerciseName),
      subtitle: Text(formattedDescription),
      trailing: imageUrl != null
          ? IconButton(
              icon: Icon(Icons.play_arrow),
              onPressed: () {
                _playExerciseVideo(context, imageUrl, formattedDescription);
              },
            )
          : null,
    );
  }

  void _playExerciseVideo(BuildContext context, String? videoUrl, String description) async {
    if (videoUrl != null) {
      final firebaseStorageRef = firebase_storage.FirebaseStorage.instance.refFromURL(videoUrl);
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

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.imageUrl)
      ..addListener(() {
        setState(() {});
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
    Color textColor = Theme.of(context).textTheme.bodyText2!.color!;
    return Scaffold(
      appBar: AppBar(
        title: Text('Info', style: TextStyle(color: textColor)),
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
                    Container(
                      padding: EdgeInsets.all(8),
                      child: _controller.value.isInitialized
                          ? AspectRatio(
                              aspectRatio: _controller.value.aspectRatio,
                              child: VideoPlayer(_controller),
                            )
                          : Container(),
                    ),
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
