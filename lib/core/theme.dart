import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED)),
  appBarTheme: const AppBarTheme(centerTitle: true),
  inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
);
