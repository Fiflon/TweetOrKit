class TweetCreator {
  final String creatorUsername;
  final String creatorName;

  TweetCreator({
    required this.creatorUsername,
    required this.creatorName,
  });

  factory TweetCreator.fromMap(Map<String, dynamic> map) {
    return TweetCreator(
      creatorUsername: map['creatorUsername'] as String,
      creatorName: map['creatorName'] as String,
    );
  }
}