// lib/supabase_options.dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Similar to firebase_options.dart but for Supabase.
///
/// Contains your project credentials and an initializer.
class SupabaseOptions {
  static const String supabaseUrl = 'https://zmpfqhmlesnkflbuoyzj.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InptcGZxaG1sZXNua2ZsYnVveXpqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwNTg2MjcsImV4cCI6MjA3NTYzNDYyN30.oWtCFU3AGBRh6MFyjzRKrZ2KzH_W_MsksX1fBkER1QE';

  /// Initialize Supabase for your app (call this before `runApp()`).
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true,
    );
  }

  /// Shortcut getter to access Supabase client globally.
  static SupabaseClient get client => Supabase.instance.client;
}
