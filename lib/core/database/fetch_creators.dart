import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tweetorkit/core/database/local_database.dart';

Future<void> fetchAndStoreUsernames() async {
  final QuerySnapshot<Map<String, dynamic>> snapshot =
    await FirebaseFirestore.instance.collection('tweetCreators').get();

  final List<Map<String, dynamic>> tweetCreators = snapshot.docs
    .map((doc) {
      final data = doc.data();
      return {
        'creatorUsername': data['creatorUsername'],
        'creatorName': data['creatorName'],
      };
    }).toList();

    for (final creator in tweetCreators) {
      await LocalDatabase.instance.insertTweetCreator(creator);
    }
}
