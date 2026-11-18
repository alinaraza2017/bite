import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Used when the database is not in the tree, including widget tests.
class TitlePage extends StatelessWidget {
  const TitlePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(title, style: AppTextStyles.heading),
      ),
    );
  }
}
