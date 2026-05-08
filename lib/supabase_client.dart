import 'package:supabase/supabase.dart';

class SupabaseConfig {
  static const String url = 'https://iigfolptnogwodvgnlfb.supabase.co';
  static const String anonKey = 'sb_publishable_jgtzpQmYEeFiLeNcbnNPdQ_NoFTAbQK';
}

final supabase = SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);
