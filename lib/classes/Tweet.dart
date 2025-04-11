import 'package:cloud_firestore/cloud_firestore.dart';

class Tweet {
  final String id; // Identyfikator dokumentu
  final String usernameTweet;
  final String textTweet;
  final DateTime dateTweet;
  final bool isRealTweet;
  final String creatorId;
  final int correctGuesses;

  final List<Map<String, dynamic>> listOfGuesses;

  Tweet({
    required this.id,
    required this.usernameTweet,
    required this.textTweet,
    required this.dateTweet,
    required this.isRealTweet,
    required this.creatorId,
    required this.correctGuesses,
    required this.listOfGuesses,
  });

  factory Tweet.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    QuerySnapshot<Map<String, dynamic>> docs,
  ) {
    final data = doc.data()!;
    final listData =
        docs.docs.map((doc) {
          final data = doc.data();
          return {
            'guesserId': data['guesserId'] ?? 'Unknown',
            'isGuessCorrect': data['isGuessCorrect'] ?? false,
          };
        }).toList();
    return Tweet(
      id: doc.id, // Pobranie identyfikatora dokumentu
      usernameTweet: data['usernameTweet'] ?? 'Unknown',
      textTweet: data['textTweet'] ?? 'No text available',
      dateTweet: (data['dateTweet'] as Timestamp).toDate(),
      isRealTweet: data['isRealTweet'] ?? false,
      creatorId: data['creatorId'] ?? 'Unknown',
      correctGuesses: data['correctGuesses'] ?? 0,
      listOfGuesses: listData,
    );
  }

  Future<List<Map<String, dynamic>>> fetchGuesses() async {
    try {
      // Pobierz dokumenty z podkolekcji "guesses" dla danego tweeta
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('tweets')
              .doc(id) // Użycie id instancji Tweet
              .collection('guesses')
              .get();

      // Przekształć dokumenty na listę map
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'guesserId': data['guesserId'] ?? 'Unknown',
          'isGuessCorrect': data['isGuessCorrect'] ?? false,
        };
      }).toList();
    } catch (e) {
      print('Error fetching correct guesses: $e');
      return [];
    }
  }
}
