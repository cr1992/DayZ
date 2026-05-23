import 'package:flutter/material.dart';
import 'package:dayz/demo/debug_home.dart';

class DayZApp extends StatelessWidget {
  const DayZApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DayZ',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const DebugHome(),
    );
  }
}
