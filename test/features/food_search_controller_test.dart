import 'package:flutter_test/flutter_test.dart';

import 'package:bite/data/models/food.dart';
import 'package:bite/features/log_food/food_search_controller.dart';

void main() {
  testWidgets('debounce does not search on every keystroke', (tester) async {
    var searches = 0;
    final FoodSearchController controller = FoodSearchController(
      search: (String query, List<String>? categories) async {
        searches += 1;
        return const <Food>[];
      },
      recents: () async => const <Food>[],
    );
    await tester.pump();
    expect(searches, 0);

    controller.setQuery('c');
    controller.setQuery('ch');
    controller.setQuery('cha');
    await tester.pump(const Duration(milliseconds: 149));
    expect(searches, 0);

    await tester.pump(const Duration(milliseconds: 1));
    expect(searches, 1);
    controller.dispose();
  });
}
