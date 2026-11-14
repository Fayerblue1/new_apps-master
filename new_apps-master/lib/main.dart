import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://ptzdkukkieyqbjigxlhi.supabase.co',
      anonKey: 'sb_publishable_4Fi7ttpFGv7Ifw90bza9hw_MNqB5QxA',
    );
  } catch (e) {
    debugPrint('Gagal inisialisasi Supabase: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kabar',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFC8411F),
        useMaterial3: true,
      ),

      home: const SplashScreen(),
    );
  }
}
