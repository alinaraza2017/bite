import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/food.dart';

/// Looks up foods. Tests pass a counter so they can see how often this runs.
typedef FoodLookup = Future<List<Food>> Function(
  String query,
  List<String>? categories,
);

/// Holds the search box, the selected chip, and the list on screen.
class FoodSearchController extends ChangeNotifier {
  FoodSearchController({
    required FoodLookup search,
    required Future<List<Food>> Function() recents,
  }) : _search = search,
       _recents = recents {
    _load();
  }

  final FoodLookup _search;
  final Future<List<Food>> Function() _recents;

  Timer? _debounce;
  int _ticket = 0;

  String query = '';
  List<String>? categories;
  List<Food> foods = [];
  bool showingRecents = true;
  bool ready = false;
  Object? error;

  void setQuery(String next) {
    query = next;
    _debounce?.cancel();
    // Wait 150 ms after the last letter. A fast typist does not hit SQLite
    // once per keystroke.
    _debounce = Timer(const Duration(milliseconds: 150), _load);
  }

  void selectCategories(List<String>? next) {
    final bool same = _sameCategories(categories, next);
    categories = same ? null : next;
    _debounce?.cancel();
    _load();
  }

  bool _sameCategories(List<String>? a, List<String>? b) {
    if (a == null || b == null || a.length != b.length) {
      return false;
    }
    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  Future<void> _load() async {
    final int ticket = ++_ticket;
    final bool wantRecents =
        query.trim().isEmpty && (categories == null || categories!.isEmpty);
    try {
      final List<Food> next = wantRecents
          ? await _recents()
          : await _search(query, categories);
      if (ticket != _ticket) {
        return;
      }
      foods = next;
      showingRecents = wantRecents;
      error = null;
      ready = true;
    } catch (loadError) {
      if (ticket != _ticket) {
        return;
      }
      error = loadError;
      ready = true;
    }
    notifyListeners();
  }

  /// Runs the last search again after an error.
  void retry() {
    _debounce?.cancel();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ticket += 1;
    super.dispose();
  }
}
