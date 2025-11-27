import 'package:flutter/material.dart';
import 'package:proyecto_eventos/services/auth_service.dart';
import 'package:proyecto_eventos/theme/app_theme.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _auth = AuthService();
  bool _estaCargando = false;

  void _showSnackBar(String message, {Color? backgroundColor, IconData? icon}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor ?? appTheme.colorScheme.primary,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
  setState(() => _estaCargando = true);

  try {
    try {
      await _auth.signOutAll();
    } catch (_) {}

    final usuario = await _auth.signInWithGoogle();

    if (usuario == null && mounted) {
      _showSnackBar('Inicio de sesión cancelado', backgroundColor: Colors.orange, icon: Icons.warning);
      return;
    }

    if (usuario != null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  } on Exception catch (e) {
    if (!mounted) return;
    final msg = e.toString().toLowerCase();
    if (msg.contains('apiexception: 7') || msg.contains('network_error') || msg.contains('network')) {
      _showSnackBar(
        'Error de red o Google Play Services. Prueba en un dispositivo con Google Play o revisa la configuración OAuth.',
        backgroundColor: Colors.red,
        icon: Icons.wifi_off,
      );
    } else {
      _showSnackBar('Error al iniciar sesión: ${e.toString()}', backgroundColor: Colors.red, icon: Icons.error);
    }
  } finally {
    if (mounted) setState(() => _estaCargando = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final ButtonStyle? themeButtonStyle = Theme.of(context).elevatedButtonTheme.style;

    final ButtonStyle finalButtonStyle = themeButtonStyle ??
        ElevatedButton.styleFrom(
          backgroundColor: appTheme.colorScheme.primary,
          foregroundColor: appTheme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          textStyle: const TextStyle(fontSize: 18),
        );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF212121), Color(0xFFFFC107)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event, size: 100, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  "MyEventsApp",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Organiza y comparte tus eventos fácilmente",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _estaCargando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.login, color: Colors.white),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(_estaCargando ? 'Ingresando...' : 'Ingresar con Google',
                          style: const TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                    style: finalButtonStyle,
                    onPressed: _estaCargando ? null : _signInWithGoogle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
