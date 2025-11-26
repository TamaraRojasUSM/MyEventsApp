import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_eventos/theme/app_theme.dart';
import 'widgets/auth_gate.dart';
import 'screens/add_event_page.dart';
import 'screens/home_page.dart' as home;
import 'screens/detalle_evento_page.dart' as detalle;
import 'screens/login_page.dart'; 

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: appTheme,
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginPage(), 
        '/home': (context) => const home.HomePage(),
        '/agregar_evento': (context) => const AddEventPage(),
        '/detalle_evento': (context) {
          final eventoId = ModalRoute.of(context)!.settings.arguments as String;
          return detalle.DetalleEventoPage(eventoId: eventoId);
        },
      },
    );
  }
}
