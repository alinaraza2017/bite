// How it works: the form screens call these before saving.
// A bad number returns a sentence. A good number returns null.

String? validateAge(String raw) {
  final int? age = int.tryParse(raw.trim());
  if (age == null || age < 10 || age > 100) {
    return 'Age must be 10 to 100 years.';
  }
  return null;
}

String? validateHeight(String raw) {
  final double? height = double.tryParse(raw.trim());
  if (height == null || height < 100 || height > 250) {
    return 'Height must be 100 to 250 cm.';
  }
  return null;
}

String? validateWeight(String raw) {
  final double? weight = double.tryParse(raw.trim());
  if (weight == null || weight < 25 || weight > 300) {
    return 'Weight must be 25 to 300 kg.';
  }
  return null;
}
