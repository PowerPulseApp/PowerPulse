import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({Key? key}) : super(key: key);

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final List<Map<String, String>> exercises = [
    {'name': 'Push-ups', 'videoPath': 'assets/videos/pushups.mp4'},
    {'name': 'Sit-ups', 'videoPath': 'assets/videos/situps.mp4'},
    {'name': 'Squats', 'videoPath': 'assets/videos/squats.mp4'},
    {'name': 'Lunges', 'videoPath': 'assets/videos/lunges.mp4'},
    {'name': 'incline bench', 'videoPath': 'assets/videos/incline.mp4'},
    // Add more exercises as needed
  ];

  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    // Initialize video player controller
    _videoPlayerController = VideoPlayerController.asset('');
    // Initialize Chewie controller
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: false,
      // You can customize other Chewie properties here
    );
  }

  @override
  void dispose() {
    // Dispose the video player controller and Chewie controller when the screen is disposed
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose an Exercise'),
      ),
      body: ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(exercises[index]['name']!),
            trailing: IconButton(
              icon: Icon(Icons.info),
              onPressed: () {
                // Show video player dialog
                _showVideoPlayerDialog(context, exercises[index]['videoPath']!);
              },
            ),
          );
        },
      ),
    );
  }

  void _showVideoPlayerDialog(BuildContext context, String videoPath) {
    // Initialize video player controller with the selected video path
    _videoPlayerController = VideoPlayerController.asset(videoPath);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Chewie(
            controller: _chewieController,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
