import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  // Supabase
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get supabaseServiceRoleKey =>
      dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

  // PowerSync
  static String get powerSyncUrl => (dotenv.env['POWERSYNC_URL'] ?? '').trim();

  // Firebase
  static String get fcmServerKey => dotenv.env['FCM_SERVER_KEY'] ?? '';
  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  // ========================
  // 🧠 AI Providers
  // ========================
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static String get claudeApiKey => dotenv.env['CLAUDE_API_KEY'] ?? '';

  static String get mistralApiKey => dotenv.env['MISTRAL_API_KEY'] ?? '';

  // App
  static String get appName => dotenv.env['APP_NAME'] ?? 'MyApp';
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';

  // Validation
  static bool get isValid {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        powerSyncUrl.isNotEmpty &&
        fcmServerKey.isNotEmpty;
  }
}
