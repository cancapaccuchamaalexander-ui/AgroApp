import 'package:flutter/material.dart';
import 'services/notificacion_service.dart';
import 'theme/app_theme.dart'; // 
import 'screens/home_scren.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const AgroApp());
}

class AgroApp extends StatelessWidget {
  const AgroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light, // 👈 antes tenías ThemeData(colorSchemeSeed: Colors.green, ...)
      home: const HomeScreen(),
    );
  }
}