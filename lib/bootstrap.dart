import 'package:flutter/material.dart';

import 'app.dart';
import 'core/constants/app_info.dart';
import 'core/theme/bite_spacing.dart';
import 'core/theme/bite_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/bite_repos.dart';
import 'data/db/database_helper.dart';
import 'data/seed/exercise_seeder.dart';
import 'data/seed/food_seeder.dart';

/// Opens the database and seeds foods before the tab shell is shown.
class BiteBootstrap extends StatefulWidget {
  const BiteBootstrap({super.key});

  @override
  State<BiteBootstrap> createState() => _BiteBootstrapState();
}

class _BiteBootstrapState extends State<BiteBootstrap> {
  late Future<BiteRepos> _ready;

  @override
  void initState() {
    super.initState();
    _ready = _prepare();
  }

  Future<BiteRepos> _prepare() async {
    final database = await DatabaseHelper.instance.open();
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await FoodSeeder().seed(database, preferences);
    await ExerciseSeeder().seed(database, preferences);
    return BiteRepos(database);
  }

  void _retry() {
    setState(() {
      _ready = _prepare();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BiteRepos>(
      future: _ready,
      builder: (BuildContext context, AsyncSnapshot<BiteRepos> snapshot) {
        if (snapshot.hasError) {
          return _Gate(
            child: _ErrorBody(error: snapshot.error, onRetry: _retry),
          );
        }
        final BiteRepos? repos = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done || repos == null) {
          return const _Gate(child: _LoadingBody());
        }
        return BiteApp(repos: repos);
      },
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: BiteTheme.light,
      home: Scaffold(
        // Center keeps the spinner and message in the middle of the screen.
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(BiteSpacing.lg),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: BiteSpacing.md),
        Text(
          'Getting your foods ready.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'The food list could not be loaded.',
          style: text.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: BiteSpacing.sm),
        Text(
          '$error',
          style: text.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: BiteSpacing.lg),
        FilledButton(
          onPressed: onRetry,
          child: const Text('Try again'),
        ),
      ],
    );
  }
}
