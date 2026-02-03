import 'package:flutter/material.dart';

class CaseDetailsScreen extends StatelessWidget {
  const CaseDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Case Details (Placeholder)')),
      body: const Center(
        child: Text(
          'Case details (map/audio/timeline) UI will go here (Figma).',
        ),
      ),
    );
  }
}
