import 'package:flutter/material.dart';
import 'package:acadarchivelatest/screens/auth/login_screen.dart';
import 'package:acadarchivelatest/screens/dashboard/main_screen.dart';
import 'package:acadarchivelatest/services/supabase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await SupabaseOptions.initialize();

  final session = SupabaseOptions.client.auth.currentSession;
  runApp(MainApp(isLoggedIn: session != null));
}

class MainApp extends StatefulWidget {
  final bool isLoggedIn;
  const MainApp({super.key, required this.isLoggedIn});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.light; // ✅ default theme mode

  /// Toggle between dark and light themes
  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "AcadArchive",
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      // ✅ LIGHT THEME
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: "Inter",
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FA),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
          background: const Color(0xFFF8F9FA),
        ),
      ),

      // ✅ DARK THEME — with concentrated background colors
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: "Inter",
        scaffoldBackgroundColor: const Color(0xFF0D1117), // 💙 concentrated dark
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1117),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
        cardColor: const Color(0xFF161B22), // subtle dark card color
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.blueAccent,
          background: Color(0xFF0D1117),
          surface: Color(0xFF161B22),
        ),
      ),

      // ✅ Choose screen based on login status
      home: widget.isLoggedIn
          ? MainScreen(onToggleTheme: _toggleTheme)
          : const LoginScreen(),
    );
  }
}
