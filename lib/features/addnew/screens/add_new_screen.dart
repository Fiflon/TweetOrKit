import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:tweetorkit/classes/TweetCreator.dart';
import 'package:tweetorkit/core/database/local_database.dart';

class AddNewScreen extends StatefulWidget {
  const AddNewScreen({super.key});

  @override
  State<AddNewScreen> createState() => _AddNewScreenState();
}

class _AddNewScreenState extends State<AddNewScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _tweetController = TextEditingController();
  final int _maxCharacters = 280;
  int _charactersLeft = 280;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  List<TweetCreator> _tweetCreators = [];

  @override
  void initState() {
    super.initState();
    _tweetController.addListener(() {
      setState(() {
        _charactersLeft = _maxCharacters - _tweetController.text.length;
      });
    });
    _loadTweetCreators();
  }

  Future<void> _loadTweetCreators() async {
    try {
      final creators = await LocalDatabase.instance.getTweetCreators();
      setState(() {
          _tweetCreators = creators.map((creator) => TweetCreator.fromMap(creator)).toList();
      });
    } catch (e) {
      print('Error loading tweet creators: $e');
    }
  }

  @override
  void dispose() {
    _tweetController.removeListener(() {});
    _usernameController.dispose();
    _tweetController.dispose();
    super.dispose();
  }


  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2006),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _addTweet() async {
    final user = FirebaseAuth.instance.currentUser;

    if (_usernameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username cannot be empty')),
        );
      }
      return;
    }

    if (_tweetController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tweet cannot be empty')),
        );
      }
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date and time')),
        );
      }
      return;
    }

    final DateTime fullDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      final tweetRef = await FirebaseFirestore.instance.collection('tweets').add({
        'usernameTweet': _usernameController.text.trim(),
        'textTweet': _tweetController.text.trim(),
        'dateTweet': Timestamp.fromDate(fullDateTime),
        'isRealTweet': false,
        'creatorId': user?.uid ?? '0',
        'correctGuesses': 0,
      });

      // możliwe że to jest do usunięcia, wrócimy tutaj gdy submitowanie guessów będzie działać
      await tweetRef.collection('guesses').add({
      'guesserId': '0',
      'isGuessCorrect': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tweet added successfully!')),
        );
      }

      _usernameController.clear();
      _tweetController.clear();

      setState(() {
        _selectedDate = null;
        _selectedTime = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding tweet: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj nowy Kit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tweetController,
              maxLines: 5,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_maxCharacters),
              ],
              decoration: const InputDecoration(
                labelText: 'Tweet Text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Available characters: $_charactersLeft / $_maxCharacters'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'No date selected'
                        : 'Selected date: ${_selectedDate!.toString().split(' ')[0]}',
                  ),
                ),
                TextButton(
                  onPressed: _pickDate,
                  child: const Text('Pick Date'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedTime == null
                        ? 'No time selected'
                        : 'Selected time: ${_selectedTime!.format(context)}',
                  ),
                ),
                TextButton(
                  onPressed: _pickTime,
                  child: const Text('Pick Time'),
                ),
              ],
            ),
            // Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     const Text(
            //       'Tweet Creators:',
            //       style: TextStyle(fontWeight: FontWeight.bold),
            //     ),
            //     const SizedBox(height: 8),
            //     if (_tweetCreators.isEmpty)
            //       const Text('No creators available.')
            //     else
            //       ..._tweetCreators.map((creator) => Text(creator.creatorUsername)),
            //       ..._tweetCreators.map((creator) => Text(creator.creatorName)),
            //   ],
            // ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _addTweet,
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}