import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/database/local_database.dart';

class HomeController {
  final LocalDatabase _localDb = LocalDatabase();
  final _supabase = Supabase.instance.client;

  Future<bool> checkVerification(String email) async {
    final db = await _localDb.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty && result.first['is_verified'] == 1;
  }

  Future<void> resendVerificationCode(String email) async {
    await _supabase.auth.resend(type: OtpType.signup, email: email);
  }
}
