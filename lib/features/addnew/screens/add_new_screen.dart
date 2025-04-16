import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  TweetCreator? _selectedCreator;

  @override
  void initState() {
    super.initState();
    _tweetController.addListener(() {
      setState(() {
        _charactersLeft = _maxCharacters - _tweetController.text.length;
      });
    });
    _loadTweetCreators();
    _selectedCreator = _tweetCreators.isNotEmpty ? _tweetCreators[0] : null;
  }

  Future<void> _loadTweetCreators() async {
    try {
      final creators = await LocalDatabase.instance.getTweetCreators();
      setState(() {
        _tweetCreators =
            creators.map((creator) => TweetCreator.fromMap(creator)).toList();
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
      lastDate: DateTime.now(),
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

    if (_tweetController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tweet nie może być pusty')));
      }
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wybierz datę i godzinę')),
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
      await FirebaseFirestore.instance
          .collection('tweets')
          .add({
            'usernameTweet': _selectedCreator!.creatorUsername,
            'textTweet': _tweetController.text.trim(),
            'dateTweet': Timestamp.fromDate(fullDateTime),
            'isRealTweet': false,
            'creatorId': user?.uid ?? '0',
            'correctGuesses': 0,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dodawanie tweeta zakończone sukcesem!')),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd podczas dodawania Tweeta: $e')));
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
      appBar: AppBar(title: const Text('Dodaj nowy Kit')),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButton(
                value: _selectedCreator,
                hint: const Text('Wybierz twórcę'),
                icon: const Icon(Icons.arrow_drop_down),
                isExpanded: true,
                onChanged:
                    (value) => setState(() {
                      _selectedCreator = value;
                    }),
                items:
                    _tweetCreators.map((creator) {
                      return DropdownMenuItem(
                        value: creator,
                        child: Text(creator.creatorName),
                      );
                    }).toList(),
              ),
              TextField(
                controller: _tweetController,
                maxLines: 5,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(_maxCharacters),
                ],
                decoration: const InputDecoration(
                  labelText: 'Treść Tweeta',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Dostępnych znaków: $_charactersLeft / $_maxCharacters',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'Nie wybrano daty'
                          : 'Wybrana data: ${_selectedDate!.toString().split(' ')[0]}',
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Wybierz datę'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedTime == null
                          ? 'Nie wybrano godziny'
                          : 'Wybrana godzina: ${_selectedTime!.format(context)}',
                    ),
                  ),
                  TextButton(
                    onPressed: _pickTime,
                    child: const Text('Wybierz godzinę'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _addTweet,
                child:
                    _isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('Zapisz'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
