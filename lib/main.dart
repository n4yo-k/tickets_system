import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

// Credenciales de Supabase
const String supabaseUrl = 'https://pbdmcbxpqdwndsntwicn.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBiZG1jYnhwcWR3bmRzbnR3aWNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjE4NzUsImV4cCI6MjA3OTczNzg3NX0.FS6PGARMGJPsliHARhk15AuWm5qjFzzSzqQit00EnCI';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true, // Activar debug para ver más detalles
    );
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Supabase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Tickets',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // Mientras se carga el estado de autenticación
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Verificar si hay error en el stream
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }

          // Obtener la sesión actual
          final session = snapshot.data?.session;
          
          debugPrint('Auth State: session = $session');

          // Si hay sesión, mostrar HomeScreen
          if (session != null) {
            return const HomeScreen();
          }

          // Si no hay sesión, mostrar LoginScreen
          return const LoginScreen();
        },
      ),
    );
  }
}
