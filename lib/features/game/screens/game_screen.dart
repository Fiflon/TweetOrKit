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
  final PageController _pageController = PageController();
  Color _startColor = Colors.transparent;
  Color _endColor = Colors.transparent;

  Tweet? currentTweet;

  bool _isLoading = true;
  bool _isButtonDisabled = false;
  //bool? previousGuess;

  String? _previousGuessMessage;
  String? _currentGuessMessage;
  bool? _isCorrect;
  double? _correctGuessPercentage;

  @override
  void initState() {
    super.initState();
    _fetchTweet();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchTweet() async {
    try {
      setState(() {
        _isLoading = true;

        _previousGuessMessage = null;
        _currentGuessMessage = null;
        _isCorrect = null;
        _correctGuessPercentage = null;
      });

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
            _isButtonDisabled = false; 
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

  void _handleJudgment(bool judgedTweet, Tweet currentTweet) async {
    MaterialColor color;
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    var isGuessCorrect = false;

    // Pobierz odpowiedź użytkownika tylko raz
    final tweetRef = FirebaseFirestore.instance
        .collection('tweets')
        .doc(currentTweet.id);
    final guessQuery =
        await tweetRef
            .collection('guesses')
            .where('guesserId', isEqualTo: currentUserId)
            .limit(1)
            .get();

    String? guessDocId;
    bool? previousGuess;

    if (guessQuery.docs.isNotEmpty) {
      final guessDoc = guessQuery.docs.first;
      guessDocId = guessDoc.id; // Zapisz ID dokumentu odpowiedzi

      previousGuess = guessDoc['isGuessCorrect'];
    }

    // Logika oceny odpowiedzi
    if (judgedTweet & currentTweet.isRealTweet) {
      color = Colors.blue;
      isGuessCorrect = true;
    } else if (!judgedTweet & !currentTweet.isRealTweet) {
      color = Colors.red;
      isGuessCorrect = true;
    } else {
      color = Colors.blueGrey;
    }

    if (guessDocId != null) {
      // Jeśli użytkownik już odpowiedział, zaktualizuj istniejący dokument
      await tweetRef.collection('guesses').doc(guessDocId).update({
        'isGuessCorrect': isGuessCorrect,
      });
      print("Odpowiedź użytkownika została zaktualizowana.");
    } else {
      // Jeśli użytkownik jeszcze nie odpowiedział, dodaj nowy dokument
      await tweetRef.collection('guesses').add({
        'isGuessCorrect': isGuessCorrect,
        'guesserId': currentUserId,
      });
    }

    if (isGuessCorrect && (previousGuess == null || previousGuess == false)) {
      await tweetRef.update({'correctGuesses': FieldValue.increment(1)});
    }

    if (!isGuessCorrect && previousGuess == true) {
      await tweetRef.update({'correctGuesses': FieldValue.increment(-1)});
    }

    // Obsługa prezentacji wyniku
    final guessesSnapshot = await tweetRef.collection('guesses').get();
    final totalGuesses = guessesSnapshot.docs.length;
    final correctGuesses = (await tweetRef.get()).data()?['correctGuesses'] ?? 0;

    double percentage = totalGuesses > 0 ? (correctGuesses / totalGuesses) * 100 : 0;

    _previousGuessMessage = previousGuess != null
        ? "Twoja poprzednia odpowiedź: ${previousGuess ? 'Prawidłowa' : 'Nieprawidłowa'}"
        : "Nie zgadywałeś jeszcze tego tweeta.";
    _currentGuessMessage = isGuessCorrect
        ? "Twoja odpowiedź jest prawidłowa!"
        : "Twoja odpowiedź jest nieprawidłowa.";
    _isCorrect = isGuessCorrect;
    _correctGuessPercentage = percentage;

    // Zaktualizuj stan aplikacji
    setState(() {
      _startColor = color.withValues(alpha: 0.8);
      _endColor = color.withValues(alpha: 0);
      _isButtonDisabled = true;
    });

    // Przywróć gradient po 5 sekundach
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
      appBar: AppBar(title: const Text('Tweet czy Kit?')),
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
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                _fetchTweet();
                setState(() {
                  _startColor = Colors.transparent;
                  _endColor = Colors.transparent;
                });
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_isLoading)
                                const Center(child: CircularProgressIndicator())
                              else if (currentTweet != null)
                                TweetWidget(
                                  userName: currentTweet?.usernameTweet ?? 'Nieznany',
                                  tweetText: currentTweet?.textTweet ?? 'Tekst nie jest dostępny',
                                  date: currentTweet!.dateTweet.toString(),
                                )
                              else
                                const Center(child: Text('Żaden tweet nie jest dostępny')),
                              const SizedBox(height: 16),
                              if (_previousGuessMessage != null || _currentGuessMessage != null || _isCorrect != null || _correctGuessPercentage != null)
                                Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (_previousGuessMessage != null)
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.history,
                                                color: Colors.black,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _previousGuessMessage!,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (_currentGuessMessage != null && _isCorrect != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 16),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _isCorrect!
                                                      ? Icons.check_circle
                                                      : Icons.error,
                                                  color: _isCorrect!
                                                      ? Colors.pinkAccent
                                                      : Colors.blueGrey,
                                                  size: 24,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _currentGuessMessage!,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: _isCorrect!
                                                          ? Colors.pinkAccent
                                                          : Colors.blueGrey,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        const SizedBox(height: 16),
                                        if (_correctGuessPercentage != null)
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.only(bottom: 8),
                                                child: Text(
                                                  "Procent poprawnych odpowiedzi:",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                              Stack(
                                                children: [
                                                  Container(
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      color: Colors.blueGrey,
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                  ),
                                                  FractionallySizedBox(
                                                    widthFactor: _correctGuessPercentage! / 100,
                                                    child: Container(
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: Colors.pinkAccent,
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text(
                                                  "${_correctGuessPercentage!.toStringAsFixed(1)}%",
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isButtonDisabled
                                  ? null
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
                              onPressed: _isButtonDisabled
                                  ? null
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
                );
              },
            ),
          ],
        ),
    );
  }
}
