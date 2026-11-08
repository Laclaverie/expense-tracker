import 'package:flutter/material.dart';

void main() => runApp(const MobileApp());

/// Placeholder shell: the real screens come in later tasks.
class MobileApp extends StatelessWidget {
  const MobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Dépenses',
      home: Scaffold(body: SizedBox.shrink()),
    );
  }
}
