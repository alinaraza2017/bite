import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

// How it works: the password is never saved. A random salt is mixed in,
// then hashed. Login hashes the same way and compares the result.
// Everything stays in SQLite. There is no server.

class AuthResult {
  const AuthResult({this.accountId, this.name, this.error});

  final int? accountId;
  final String? name;
  final String? error;

  bool get ok => accountId != null && error == null;
}

/// Tells the router when someone logs in or out.
class SessionController extends ChangeNotifier {
  SessionController(this.accountId);

  int? accountId;

  void setAccount(int? id) {
    accountId = id;
    notifyListeners();
  }
}

class AuthRepository {
  AuthRepository(this._preferences, this._database);

  final SharedPreferences _preferences;
  final Database? _database;

  static const String accountKey = 'logged_in_account_id';
  static const String welcomeNameKey = 'welcome_name';

  /// Last person who signed up or logged in. Kept after log out so the
  /// login screen can say "Welcome, Ayesha".
  String? welcomeName() {
    return _usable(_preferences.getString(welcomeNameKey));
  }

  /// The name to show. "Friend" is ignored. The account row wins over a bad save.
  Future<String?> accountDisplayName() async {
    final Database? database = _database;
    final int? id = currentAccountId();
    if (database != null && id != null) {
      final String? named = await _nameWhere(database, 'id = ?', <Object>[id]);
      if (named != null) {
        await _preferences.setString(welcomeNameKey, named);
        return named;
      }
    }
    final String? saved = welcomeName();
    if (saved != null) {
      return saved;
    }
    if (database == null) {
      return null;
    }
    return _nameWhere(database, null, null);
  }

  Future<String?> _nameWhere(
    Database database,
    String? where,
    List<Object>? args,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'accounts',
      columns: <String>['name'],
      where: where,
      whereArgs: args,
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _usable(rows.first['name'] as String?);
  }

  String? _usable(String? raw) {
    if (raw == null) {
      return null;
    }
    final String name = raw.trim();
    if (name.isEmpty || name.toLowerCase() == 'friend') {
      return null;
    }
    return name;
  }

  int? currentAccountId() {
    return _preferences.getInt(accountKey);
  }

  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final String? problem = _check(name: name, email: email, password: password);
    if (problem != null) {
      return AuthResult(error: problem);
    }
    final Database? database = _database;
    if (database == null) {
      return const AuthResult(error: 'The database is not open yet.');
    }
    final String salt = _newSalt();
    try {
      final String cleanName = name.trim();
      final int id = await database.insert('accounts', <String, Object?>{
        'name': cleanName,
        'email': email.trim(),
        'salt': salt,
        'password_hash': _hash(password, salt),
        'created_at': DateTime.now().toIso8601String(),
      });
      await _preferences.setInt(accountKey, id);
      await _preferences.setString(welcomeNameKey, cleanName);
      return AuthResult(accountId: id, name: cleanName);
    } on DatabaseException {
      return const AuthResult(error: 'That email is already used.');
    }
  }

  Future<AuthResult> logIn({
    required String email,
    required String password,
  }) async {
    final Database? database = _database;
    if (database == null) {
      return const AuthResult(error: 'The database is not open yet.');
    }
    final List<Map<String, Object?>> rows = await database.query(
      'accounts',
      where: 'email = ? COLLATE NOCASE',
      whereArgs: <Object>[email.trim()],
    );
    if (rows.isEmpty) {
      return const AuthResult(error: 'Email or password is wrong.');
    }
    final Map<String, Object?> row = rows.first;
    final String salt = row['salt'] as String;
    final String saved = row['password_hash'] as String;
    if (saved != _hash(password, salt)) {
      return const AuthResult(error: 'Email or password is wrong.');
    }
    final int id = (row['id'] as num).toInt();
    final String accountName = (row['name'] as String).trim();
    await _preferences.setInt(accountKey, id);
    await _preferences.setString(welcomeNameKey, accountName);
    return AuthResult(accountId: id, name: accountName);
  }

  Future<void> logOut() async {
    await _preferences.remove(accountKey);
  }

  String? _check({
    required String name,
    required String email,
    required String password,
  }) {
    if (name.trim().length < 2) {
      return 'Enter your name.';
    }
    final String mail = email.trim();
    if (!mail.contains('@') || !mail.contains('.')) {
      return 'Enter a real email.';
    }
    if (password.length < 6) {
      return 'Use at least 6 characters.';
    }
    return null;
  }

  String _newSalt() {
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hash(String password, String salt) {
    return sha256.convert(utf8.encode('$salt$password')).toString();
  }
}
