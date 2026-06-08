import 'package:flutter/material.dart';
import 'package:lembreme_app/services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/cadastro_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o serviço de notificação
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LembreMe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // ROTA INICIAL
      initialRoute: '/login',
      // DEFINIÇÃO DAS ROTAS
      routes: {
        '/login': (context) => const LoginScreen(),
        '/cadastro': (context) => const CadastroScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
      // CASO A ROTA NÃO EXISTA
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );
      },
    );
  }
}