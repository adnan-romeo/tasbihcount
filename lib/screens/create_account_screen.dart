import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app.dart';
import '../services/auth_service.dart';
import '../widgets/app_input_field.dart';
import '../widgets/auth_screen_layout.dart';
import '../widgets/outlined_action_button.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signUp(
        username: username,
        email: email,
        password: password,
      );

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppSessionKeys.offlineMode, false);

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.counter,
        (route) => false,
      );
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

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      title: 'Create Account',
      child: Column(
        children: [
          AppInputField(
            hintText: 'Username or E-mail',
            controller: _usernameController,
          ),
          const SizedBox(height: 12),
          AppInputField(hintText: 'E-mail', controller: _emailController),
          const SizedBox(height: 12),
          AppInputField(
            hintText: 'Password',
            obscureText: true,
            controller: _passwordController,
          ),
          const SizedBox(height: 12),
          AppInputField(
            hintText: 'Confirm Password',
            obscureText: true,
            controller: _confirmPasswordController,
          ),
          const SizedBox(height: 18),
          OutlinedActionButton(
            label: _isLoading ? 'Loading...' : 'Create Account',
            onPressed: _isLoading ? () {} : _createAccount,
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
            label: 'Login',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 14),
          OutlinedActionButton(
            label: 'Continue Offline',
            onPressed: () async {
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              await prefs.setBool(AppSessionKeys.offlineMode, true);

              if (!context.mounted) {
                return;
              }

              Navigator.pushNamed(context, AppRoutes.counter);
            },
          ),
        ],
      ),
    );
  }
}
