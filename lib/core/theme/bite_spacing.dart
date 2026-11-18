/// 4-point spacing scale from the spec. Widgets use these instead of raw numbers.
class BiteSpacing {
  BiteSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Cards are 16 and sheets are 28. Chips use a stadium shape, so they have no number.
class BiteRadius {
  BiteRadius._();

  static const double card = 16;
  static const double sheet = 28;
}
