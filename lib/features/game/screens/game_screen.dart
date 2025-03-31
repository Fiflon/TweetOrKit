import 'package:flutter/material.dart';
import 'package:tweetorkit/features/game/widgets/tweet_widget.dart'; // Import TweetWidget

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tweet or Kit?'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TweetWidget(
              userName: 'Some Madman',
              tweetText: 'This is the text of the tweet. I can be quite long. Even occupy a few lines.',
              date: '12:00 PM, Apr 1 2025',
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Handle Tweet
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                  ),
                  child: Text('Tweet'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Handle Kit 
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                  child: Text('Kit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}