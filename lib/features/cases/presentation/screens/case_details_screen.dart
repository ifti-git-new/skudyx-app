import 'package:flutter/material.dart';

class CaseDetailsScreen extends StatelessWidget {
  final String caseId;

  const CaseDetailsScreen({super.key, required this.caseId});

  // ... keep rest of your code unchanged
  @override
  Widget build(BuildContext context) {
    // use caseId where needed
    return Scaffold(body: SafeArea(child: Text('Case: $caseId')));
  }
}
