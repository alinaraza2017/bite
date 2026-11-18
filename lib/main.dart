import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bootstrap.dart';

void main() {
  // Needed before path_provider and SQLite can ask Android for a folder.
  WidgetsFlutterBinding.ensureInitialized();
  // Poppins is already in assets/fonts. This stops google_fonts from
  // trying the network if a style asks for it later.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const BiteBootstrap());
}
