import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';

// TODO: replace with your real Supabase project values
// (Project Settings -> API in the Supabase dashboard)
const supabaseUrl = 'https://gagkuujexgfervujlrtp.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdhZ2t1dWpleGdmZXJ2dWpscnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY3OTQ2NDIsImV4cCI6MjEwMjM3MDY0Mn0.DNi3w9zQMn7mNjyt7f_Q2kd3CaCpBUiQ8U90LAydyWM';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const AppStoreApp());
}

class AppStoreApp extends StatelessWidget {
  const AppStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
