import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_router.dart';
import 'core/constants/app_info.dart';
import 'core/utils/greeting.dart';
import 'core/theme/bite_theme.dart';
import 'data/bite_repos.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'domain/models.dart';
import 'features/home/day_board.dart';
import 'features/onboarding/profile_provider.dart';

// How it works: the profile is loaded from SQLite before the first screen.
// There is no store. Premium stays a flag that the screens do not turn on.

class BiteApp extends StatefulWidget {
  const BiteApp({super.key, this.repos});

  /// Null in widget tests. The real app passes the open database.
  final BiteRepos? repos;

  @override
  State<BiteApp> createState() => _BiteAppState();
}

class _BiteAppState extends State<BiteApp> {
  GoRouter? _router;
  ProfileProvider? _profiles;
  ProfileRepository? _profileRepository;
  AuthRepository? _auth;
  SessionController? _session;
  DayBoard? _board;

  @override
  void initState() {
    super.initState();
    final BiteRepos? repos = widget.repos;
    if (repos != null) {
      _board = DayBoard(repos);
    }
    _open();
  }

  Future<void> _open() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final ProfileRepository repository = ProfileRepository(
      preferences,
      widget.repos?.database,
    );
    final AuthRepository auth = AuthRepository(
      preferences,
      widget.repos?.database,
    );
    final int? accountId = auth.currentAccountId();
    repository.accountId = accountId;
    final SessionController session = SessionController(accountId);
    final String? displayName = await auth.accountDisplayName();
    UserProfile? saved = await repository.load();
    if (saved != null &&
        displayName != null &&
        firstName(saved.name) == null) {
      saved = saved.copyWith(name: displayName);
      await repository.save(saved);
    }
    final ProfileProvider profiles = ProfileProvider(
      repository: repository,
      initial: saved,
    );
    final GoRouter router = createBiteRouter(repository, session);
    if (!mounted) {
      router.dispose();
      profiles.dispose();
      session.dispose();
      return;
    }
    setState(() {
      _router = router;
      _profiles = profiles;
      _profileRepository = repository;
      _auth = auth;
      _session = session;
    });
  }

  @override
  void dispose() {
    _router?.dispose();
    _profiles?.dispose();
    _session?.dispose();
    _board?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter? router = _router;
    final ProfileProvider? profiles = _profiles;
    final ProfileRepository? repository = _profileRepository;
    final AuthRepository? auth = _auth;
    final SessionController? session = _session;
    if (router == null ||
        profiles == null ||
        repository == null ||
        auth == null ||
        session == null) {
      return MaterialApp(
        title: appName,
        theme: BiteTheme.light,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final DayBoard? board = _board;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileProvider>.value(value: profiles),
        ChangeNotifierProvider<SessionController>.value(value: session),
        Provider<ProfileRepository>.value(value: repository),
        Provider<AuthRepository>.value(value: auth),
        if (board != null) ChangeNotifierProvider<DayBoard>.value(value: board),
        Provider<BiteRepos?>.value(value: widget.repos),
      ],
      child: MaterialApp.router(
        title: appName,
        theme: BiteTheme.light,
        routerConfig: router,
      ),
    );
  }
}
