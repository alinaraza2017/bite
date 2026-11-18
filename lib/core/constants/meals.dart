/// Stored meal ids. The screen shows [mealLabel].
const List<String> mealIds = <String>[
  'breakfast',
  'lunch',
  'snacks',
  'dinner',
];

String mealLabel(String id) {
  switch (id) {
    case 'breakfast':
      return 'Breakfast';
    case 'lunch':
      return 'Lunch';
    case 'snacks':
      return 'Snacks';
    case 'dinner':
      return 'Dinner';
    default:
      return id;
  }
}

String mealLetter(String id) {
  switch (id) {
    case 'breakfast':
      return 'B';
    case 'lunch':
      return 'L';
    case 'snacks':
      return 'S';
    case 'dinner':
      return 'D';
    default:
      return '?';
  }
}

/// Before 11 breakfast, 11–16 lunch, 16–19 snacks, after that dinner.
String mealForTime(DateTime time) {
  if (time.hour < 11) {
    return 'breakfast';
  }
  if (time.hour < 16) {
    return 'lunch';
  }
  if (time.hour < 19) {
    return 'snacks';
  }
  return 'dinner';
}

/// 0.5 for bowls and plates. 1 for countable pieces.
double quantityStep(String label) {
  final String lower = label.toLowerCase();
  if (lower.contains('roti') ||
      lower.contains('piece') ||
      lower.contains('chapati') ||
      lower.contains('egg') ||
      lower.contains('naan') ||
      lower.contains('paratha') ||
      lower.contains('puri') ||
      lower.contains('seekh')) {
    return 1;
  }
  return 0.5;
}
