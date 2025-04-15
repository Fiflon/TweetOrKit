import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tweetorkit/features/auth/controllers/user_controller.dart';
import 'package:pie_chart/pie_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';

  String selectedFilter = 'Wszystkie';

  bool isLoading = true;

  Map<String, dynamic> userStats = {
    'totalGuesses': 0,
    'correctGuesses': 0,
    'correctPercentage': 0.0,
  };

  Map<String, double> dataMap = {
    "Prawidłowo": 0,
    "Nieprawidłowo": 0,
  };

  var colorList = <Color>[
    Colors.purpleAccent,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    final userId = UserController.currentUser()?.uid;
    userName = UserController.currentUser()?.displayName ?? 'Unknown';

    if (userId != null) {
      final stats = await fetchUserStats(userId, selectedFilter);
      if (mounted) {
        setState(() {
          userStats = stats;
          dataMap = {
            "Prawidłowo": stats['correctGuesses'].toDouble(),
            "Nieprawidłowo": (stats['totalGuesses'] - stats['correctGuesses']).toDouble(),
          };

          if (selectedFilter == 'Wszystkie') {
            colorList = <Color>[
            Colors.purpleAccent,
            Colors.blueGrey,
          ];
          } else if (selectedFilter == 'Tweet') {
            colorList = <Color>[
            Colors.blue,
            Colors.blueGrey,
            ];
          } else if (selectedFilter == 'Kit') {
            colorList = <Color>[
            Colors.red,
            Colors.blueGrey,
            ];
          }
        });
      }
    }
  }

  Future<Map<String, dynamic>> fetchUserStats(String userId, String filter) async {
    try {
      setState(() {
        isLoading = true;
      });

      final tweetsSnapshot = await FirebaseFirestore.instance
          .collection('tweets')
          .get();

      int totalGuesses = 0;
      int correctGuesses = 0;

      for (var tweetDoc in tweetsSnapshot.docs) {
        if (filter == 'Tweet' && tweetDoc['isRealTweet'] != true) {
          continue;
        } else if (filter == 'Kit' && tweetDoc['isRealTweet'] != false) {
          continue;
        }

        final guessesSnapshot = await tweetDoc.reference
            .collection('guesses')
            .where('guesserId', isEqualTo: userId)
            .get();

        totalGuesses += guessesSnapshot.docs.length;

        correctGuesses += guessesSnapshot.docs
            .where((doc) => doc['isGuessCorrect'] == true)
            .length;
      }

      double correctPercentage =
          totalGuesses > 0 ? (correctGuesses / totalGuesses) * 100 : 0;
          
      setState(() {
        isLoading = false;
      });
      return {
        'totalGuesses': totalGuesses,
        'correctGuesses': correctGuesses,
        'correctPercentage': double.parse(correctPercentage.toStringAsFixed(2)),
      };
    } catch (e) {
      print('Error fetching user stats: $e');
      return {
        'totalGuesses': 0,
        'correctGuesses': 0,
        'correctPercentage': 0.0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        child: Column(
          children: [
              Center(
              child: Text(
                'Cześć $userName!',
                style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                ),
              ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  foregroundImage: NetworkImage(
                    UserController.currentUser()?.photoURL ?? '',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      UserController.signOut();
                      Navigator.of(context).pushReplacementNamed('/');
                    },
                    child: const Text('Wyloguj się'),
                  ),
                ),
            ],),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedFilter = 'Wszystkie';
                    });
                    _loadUserStats();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedFilter == 'Wszystkie'
                        ? Colors.purpleAccent
                        : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Wszystkie'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedFilter = 'Tweet';
                    });
                    _loadUserStats();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedFilter == 'Tweet'
                        ? Colors.blue
                        : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tweet'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedFilter = 'Kit';
                    });
                    _loadUserStats();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedFilter == 'Kit'
                        ? Colors.red
                        : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kit'),
                ),
              ],
            ),
            Column(
              children: isLoading
              ? [Center(
                child: CircularProgressIndicator(), 
              )] : [
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statystyki użytkownika:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                            'Liczba zgadnięć:',
                            style: TextStyle(fontSize: 16),
                            ),
                            Text(
                            '${userStats['totalGuesses']}',
                            style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                            'Liczba poprawnych zgadnięć:',
                            style: TextStyle(fontSize: 16),
                            ),
                            Text(
                            '${userStats['correctGuesses']}',
                            style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                            'Procent poprawnych zgadnięć:',
                            style: TextStyle(fontSize: 16),
                            ),
                            Text(
                            '${userStats['correctPercentage']}',
                            style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        PieChart(
                          dataMap: dataMap,
                          chartRadius: MediaQuery.of(context).size.width * 0.6,
                          legendOptions: LegendOptions(
                            showLegends: true,
                            legendPosition: LegendPosition.bottom,
                          ),
                          chartValuesOptions: ChartValuesOptions(
                            showChartValuesInPercentage: true,
                            showChartValuesOutside: false,
                          ), 
                          colorList: colorList,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
