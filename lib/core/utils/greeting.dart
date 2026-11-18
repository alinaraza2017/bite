// How it works: the name is accounts.name for the logged-in id.
// "Friend" is ignored. An empty name is just "Welcome".

/// The comma in "Welcome, Ayesha". Change this one string to restyle it.
const String welcomeComma = ', ';

String? firstName(String? raw) {
  final String name = (raw ?? '').trim();
  if (name.isEmpty || name.toLowerCase() == 'friend') {
    return null;
  }
  return name.split(' ').first;
}

/// Profile name wins for the avatar. The account name is next.
String greetingName(String? profileName, String? accountName) {
  return firstName(profileName) ?? firstName(accountName) ?? 'there';
}

/// "Welcome, Ayesha Khan", or "Welcome" when the account name is empty.
String welcomeLine(String? accountName) {
  final String name = (accountName ?? '').trim();
  if (name.isEmpty || name.toLowerCase() == 'friend') {
    return 'Welcome';
  }
  return 'Welcome$welcomeComma$name';
}

String avatarLetter(String? profileName, String? accountName) {
  final String name = greetingName(profileName, accountName);
  if (name == 'there') {
    return 'B';
  }
  return name[0].toUpperCase();
}
