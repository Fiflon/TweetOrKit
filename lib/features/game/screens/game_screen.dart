import 'package:flutter/material.dart';
import 'package:tweetorkit/features/game/widgets/tweet_widget.dart'; // Import TweetWidget

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _isAnimating = false;
  Color _startColor = Colors.transparent;
  Color _endColor = Colors.transparent;

  void _animateGradient(Color color) {
    setState(() {
      _isAnimating = true;
      _startColor = color.withOpacity(0.5);
      _endColor = color.withOpacity(0.8);
    });

    Future.delayed(Duration(seconds: 5), () {
      setState(() {
        _isAnimating = false;
        _startColor = Colors.transparent;
        _endColor = Colors.transparent;
      });
    });
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tweet or Kit?'),
      ),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_startColor, _endColor],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TweetWidget(
                  userName: 'Some Madman',
                  tweetText: 'This is the text of the tweet. I can be quite long. Even occupy a few lines.',
                  date: '12:00 PM, Apr 1 2025',
                ),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _animateGradient(Colors.blue); // Trigger blue gradient
                          // Handle Tweet
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          minimumSize: Size(0, 100),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Tweet', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _animateGradient(Colors.red); // Trigger red gradient
                          // Handle Kit
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          minimumSize: Size(0, 100),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Kit', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}