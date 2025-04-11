import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tweetorkit/classes/Tweet.dart';
import 'package:tweetorkit/features/game/widgets/tweet_widget.dart'; // Import TweetWidget

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Color _startColor = Colors.transparent;
  Color _endColor = Colors.transparent;

  Tweet? currentTweet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTweet();
  }

  Future<void> _fetchTweet() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('tweets').limit(1).get();
      print(snapshot.docs.first.data());

      if (snapshot.docs.isNotEmpty) {
        final tweetSnapshot = snapshot.docs.first;
        final QuerySnapshot<Map<String, dynamic>> snapshotGuesses =
            await FirebaseFirestore.instance
                .collection('tweets')
                .doc(tweetSnapshot.id)
                .collection('guesses')
                .get();

        if (mounted) {
          setState(() {
            currentTweet = Tweet.fromFirestore(tweetSnapshot, snapshotGuesses);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching tweet: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _animateGradient(Color color) {
    setState(() {
      _startColor = color.withValues(alpha: 0.8);
      _endColor = color.withValues(alpha: 0);
    });

    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _startColor = Colors.transparent;
        _endColor = Colors.transparent;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tweet or Kit?')),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_endColor, _startColor],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (currentTweet != null)
                  TweetWidget(
                    userName: currentTweet?.usernameTweet ?? 'Unknown',
                    tweetText: currentTweet?.textTweet ?? 'No text available',
                    date: currentTweet!.dateTweet.toString(),
                  )
                else
                  const Center(child: Text('No tweet available')),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _animateGradient(Colors.blue);
                          // Handle Tweet
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          minimumSize: const Size(0, 100),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Tweet',
                          style: TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _animateGradient(Colors.red); // Trigger red gradient
                          // Handle Kit
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          minimumSize: const Size(0, 100),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Kit',
                          style: TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
