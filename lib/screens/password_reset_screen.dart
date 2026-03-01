import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app.dart';
import '../widgets/app_input_field.dart';
import '../widgets/auth_screen_layout.dart';
import '../widgets/outlined_action_button.dart';

class PasswordResetScreen extends StatelessWidget {
  const PasswordResetScreen({super.key});

  Future<void> _showSuccessPopup(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Text(
            'Password Reset Was Successful!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 180,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Login'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      title: 'Password Reset',
      child: Column(
        children: [
          const AppInputField(hintText: 'New Password', obscureText: true),
          const SizedBox(height: 12),
          const AppInputField(
              hintText: 'Confirm New Password', obscureText: true),
          const SizedBox(height: 18),
          OutlinedActionButton(
            label: 'Done',
            onPressed: () => _showSuccessPopup(context),
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
            label: 'Create Account',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.createAccount);
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
