import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app.dart';
import '../services/auth_service.dart';
import '../widgets/app_input_field.dart';
import '../widgets/auth_screen_layout.dart';
import '../widgets/outlined_action_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _offlineWarningShownKey = 'offline_warning_shown_v1';
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill email and password.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signIn(email: email, password: password);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppSessionKeys.offlineMode, false);

      if (!mounted) {
        return;
      }

      Navigator.pushReplacementNamed(context, AppRoutes.counter);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authService.formatAuthError(error))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final String email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first.')),
      );
      return;
    }

    if (!_emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.')),
      );
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(email: email);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If this email is registered, a reset link has been sent. Check inbox/spam.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authService.formatAuthError(error))),
      );
    }
  }

  Future<void> _showOfflineDialog() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool warningShown = prefs.getBool(_offlineWarningShownKey) ?? false;

    if (!mounted) {
      return;
    }

    if (warningShown) {
      await prefs.setBool(AppSessionKeys.offlineMode, true);

      if (!mounted) {
        return;
      }

      Navigator.pushNamed(context, AppRoutes.counter);
      return;
    }

    final bool? shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Text(
            'If you continue offline, all the data will be deleted once the app is deleted. Do you want to continue?',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'No',
                style: TextStyle(color: Colors.black),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );

    await prefs.setBool(_offlineWarningShownKey, true);

    if (!mounted) {
      return;
    }

    if (shouldContinue == true) {
      await prefs.setBool(AppSessionKeys.offlineMode, true);

      if (!mounted) {
        return;
      }

      Navigator.pushNamed(context, AppRoutes.counter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      title: 'Login',
      child: Column(
        children: [
          AppInputField(
            hintText: 'Username or E-mail',
            controller: _emailController,
          ),
          const SizedBox(height: 12),
          AppInputField(
            hintText: 'Password',
            obscureText: true,
            controller: _passwordController,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _sendPasswordReset,
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedActionButton(
            label: _isLoading ? 'Loading...' : 'Login',
            onPressed: _isLoading ? () {} : _login,
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(child: Divider(color: Colors.white24)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text('Or', style: TextStyle(fontSize: 20)),
              ),
              Expanded(child: Divider(color: Colors.white24)),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedActionButton(
            label: 'Create Account',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.createAccount);
            },
          ),
          const SizedBox(height: 14),
          OutlinedActionButton(
            label: 'Continue Offline',
            onPressed: _showOfflineDialog,
          ),
        ],
      ),
    );
  }
}
