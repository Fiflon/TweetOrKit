import 'package:flutter/material.dart';

class TweetWidget extends StatelessWidget {
  final String userName;
  final String tweetText;
  final String date;

  const TweetWidget({
    super.key,
    required this.userName,
    required this.tweetText,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24.0,
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            tweetText,
            style: TextStyle(fontSize: 16.0),
          ),
          SizedBox(height: 8.0),
          Text(
            date,
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8.0),
          Divider(
            color: Colors.grey,
            thickness: 1.0,
          ),
          SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.insert_comment),
              Icon(Icons.share),
              Icon(Icons.favorite),          
              Icon(Icons.bar_chart),
            ],
          )
        ],
      ),
    );
  }
}