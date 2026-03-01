import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app.dart';
import '../widgets/app_input_field.dart';
import '../widgets/auth_screen_layout.dart';
import '../widgets/outlined_action_button.dart';

class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      title: 'Enter OTP to verify',
      child: Column(
        children: [
          const AppInputField(hintText: 'OTP'),
          const SizedBox(height: 18),
          OutlinedActionButton(
            label: 'Verify',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Password reset works through the email reset link, not OTP in-app.',
                  ),
                ),
              );
            },
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
