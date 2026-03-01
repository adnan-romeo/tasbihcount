import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/create_account_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_counter_screen.dart';
import 'screens/statistics_screen.dart';
import 'theme/app_theme.dart';

class AppRoutes {
  static const String login = '/login';
  static const String createAccount = '/create-account';
  static const String counter = '/counter';
  static const String statistics = '/statistics';
}

class AppSessionKeys {
  static const String offlineMode = 'offline_mode_v1';
}

class TasbihCountApp extends StatelessWidget {
  const TasbihCountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tasbih Count',
      theme: AppTheme.darkTheme,
      home: const AuthGate(),
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.createAccount: (_) => const CreateAccountScreen(),
        AppRoutes.counter: (_) => const MainCounterScreen(),
        AppRoutes.statistics: (_) => const StatisticsScreen(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isReady = false;
  bool _isOfflineMode = false;

  @override
  void initState() {
    super.initState();
    _loadOfflineMode();
  }

  Future<void> _loadOfflineMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    setState(() {
      _isOfflineMode = prefs.getBool(AppSessionKeys.offlineMode) ?? false;
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (snapshot.data != null) {
          return const MainCounterScreen();
        }

        if (_isOfflineMode) {
          return const MainCounterScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
