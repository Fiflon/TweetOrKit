import 'package:flutter/material.dart';

class MainTheme {
  MainTheme._(); // _ means private constructor: it cannot be changed from outside of the file     :)
  // LIGHT MainTHEME
  static ThemeData mainTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 8, 160, 233),
    ),
  );
}
