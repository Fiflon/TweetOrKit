import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool _isButtonDisabled = false;

  @override
  void initState() {
    super.initState();
    _fetchTweet();
  }

  Future<void> _fetchTweet() async {
    try {
      final tweetsCollection = FirebaseFirestore.instance.collection('tweets');

      // Wygeneruj losowy klucz (identyfikator dokumentu)
      final randomKey = tweetsCollection.doc().id;

      // Pobierz dokumenty z identyfikatorem >= randomKey
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await tweetsCollection
              .where(FieldPath.documentId, isGreaterThanOrEqualTo: randomKey)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        // Jeśli znaleziono dokument, pobierz go
        final tweetSnapshot = snapshot.docs.first;
        final QuerySnapshot<Map<String, dynamic>> snapshotGuesses =
            await tweetsCollection
                .doc(tweetSnapshot.id)
                .collection('guesses')
                .get();

        if (mounted) {
          setState(() {
            currentTweet = Tweet.fromFirestore(tweetSnapshot, snapshotGuesses);
            _isLoading = false;
            _isButtonDisabled = false; // Aktywuj przyciski
          });
        }
      } else {
        // Jeśli nie znaleziono dokumentu, pobierz dokument z identyfikatorem < randomKey
        final QuerySnapshot<Map<String, dynamic>> fallbackSnapshot =
            await tweetsCollection
                .where(FieldPath.documentId, isLessThan: randomKey)
                .limit(1)
                .get();

        if (fallbackSnapshot.docs.isNotEmpty) {
          final tweetSnapshot = fallbackSnapshot.docs.first;
          final QuerySnapshot<Map<String, dynamic>> snapshotGuesses =
              await tweetsCollection
                  .doc(tweetSnapshot.id)
                  .collection('guesses')
                  .get();

          if (mounted) {
            setState(() {
              currentTweet = Tweet.fromFirestore(
                tweetSnapshot,
                snapshotGuesses,
              );
              _isLoading = false;
            });
          }
        } else {
          // Jeśli nadal brak dokumentów, ustaw brak danych
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching random tweet: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleJudgment(bool judgedTweet, Tweet currentTweet) {
    MaterialColor color;
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    var isGuessCorrect = false;

    final wasAnswered = currentTweet.listOfGuesses.any(
      (guess) => guess['guesserId'] == currentUserId,
    );
    if (wasAnswered) {
      final userGuess = currentTweet.listOfGuesses.firstWhere(
        (guess) => guess['guesserId'] == currentUserId,
      );
      print(
        'User has already answered. Their guess: $userGuess',
      ); // zrobic cos jak ktos juz odgadl, zeby nie dodawac kolejnego rekordu guess, a zastapic poprzedni
      //return;
    }
    if (judgedTweet & currentTweet.isRealTweet) {
      color = Colors.blue;
      isGuessCorrect = true;
    } else if (!judgedTweet & !currentTweet.isRealTweet) {
      color = Colors.red;
      isGuessCorrect = true;
    } else {
      color = Colors.blueGrey;
    }

    final tweetRef = FirebaseFirestore.instance
        .collection('tweets')
        .doc(currentTweet.id);

    tweetRef.collection('guesses').add({
      'isGuessCorrect': isGuessCorrect,
      'guesserId': currentUserId,
    });

    if (isGuessCorrect) {
      tweetRef.update({
        'correctGuesses': FieldValue.increment(1),
      }); // czy incrementowac jak ktos juz odpowiedzial?
    }

    setState(() {
      _startColor = color.withValues(alpha: 0.8);
      _endColor = color.withValues(alpha: 0);
      _isButtonDisabled = true; // Dezaktywuj przyciski
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
                        onPressed:
                            _isButtonDisabled
                                ? null // Jeśli przyciski są dezaktywowane, ustaw `null`
                                : () {
                                  if (currentTweet != null) {
                                    _handleJudgment(true, currentTweet!);
                                  }
                                },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              _isButtonDisabled ? Colors.grey : Colors.blue,
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
                        onPressed:
                            _isButtonDisabled
                                ? null // Jeśli przyciski są dezaktywowane, ustaw `null`
                                : () {
                                  if (currentTweet != null) {
                                    _handleJudgment(false, currentTweet!);
                                  }
                                },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              _isButtonDisabled ? Colors.grey : Colors.red,
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
