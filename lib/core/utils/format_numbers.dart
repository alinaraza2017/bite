/// 1420 becomes "1,420". Used everywhere a count is shown.
String formatNumber(num value) {
  final int number = value.round();
  final bool negative = number < 0;
  final String digits = number.abs().toString();
  final StringBuffer out = StringBuffer();
  for (int index = 0; index < digits.length; index++) {
    final int left = digits.length - index;
    if (index > 0 && left % 3 == 0) {
      out.write(',');
    }
    out.write(digits[index]);
  }
  if (negative) {
    return '-${out.toString()}';
  }
  return out.toString();
}

/// Weeks start on Monday. Date strips use this one constant.
const int weekStartsOn = DateTime.monday;

const List<String> weekdayLetters = <String>[
  'M',
  'T',
  'W',
  'T',
  'F',
  'S',
  'S',
];

const List<String> weekdayNames = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> _weekdays = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

const List<String> monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String weekdayLetter(DateTime day) {
  return weekdayLetters[day.weekday - weekStartsOn];
}

const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Wed, 7 Oct".
String formatDay(DateTime day) {
  final String weekday = _weekdays[day.weekday - 1];
  final String month = _months[day.month - 1];
  return '$weekday, ${day.day} $month';
}

/// "28 Sep".
String formatShort(DateTime day) {
  return '${day.day} ${_months[day.month - 1]}';
}

/// yyyy-MM-dd as a local calendar day. DateTime.parse treats that
/// string as UTC, which can land on the previous evening.
DateTime? dateFromKey(String? raw) {
  if (raw == null || raw.length < 10) {
    return null;
  }
  final List<String> parts = raw.substring(0, 10).split('-');
  if (parts.length != 3) {
    return null;
  }
  final int? year = int.tryParse(parts[0]);
  final int? month = int.tryParse(parts[1]);
  final int? day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }
  return DateTime(year, month, day);
}

DateTime dateOnly(DateTime day) {
  return DateTime(day.year, day.month, day.day);
}

/// Monday of the week that contains [day].
DateTime mondayOf(DateTime day) {
  final DateTime date = dateOnly(day);
  final int shift = (date.weekday - weekStartsOn) % 7;
  return date.subtract(Duration(days: shift));
}

bool sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool isWithinLastDays(DateTime day, DateTime today, int days) {
  final DateTime start = dateOnly(today).subtract(Duration(days: days - 1));
  final DateTime target = dateOnly(day);
  return !target.isBefore(start) && !target.isAfter(dateOnly(today));
}
