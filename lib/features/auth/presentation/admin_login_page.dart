import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import 'package:pholders_admin/store.dart';
import '../../../core/routing/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../data/models/admin_login_session.dart';
import 'widgets/auth_widgets.dart';



/// Admin sign-in, step one of two.
///
/// Submitting does not sign anyone in: `/users/admin/login` only checks the
/// password and emails a 6-digit code. The session is issued on the next page.
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    // Recorded before the request so the OTP page knows which address the code
    // went to. The password is never carried across.
    AdminLoginSession().email = email;

    StoreProvider.of<AppState>(context).dispatch(
      AdminLoginRequestAction(
        email: email,
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      converter: (store) => store.state,
      distinct: true,
      onDidChange: (prevState, state) {
        // A code was emailed. There is still no token, so this is a plain
        // navigation, not an authenticated redirect.
        final sent = state.authState.successMessage;
        if (sent != null && prevState?.authState.successMessage != sent) {
          context.go(AppRoutes.adminVerify);
        }
      },
      builder: (context, state) {
        return Form(
          key: _formKey,
          child: AuthScaffold(
            logo: Image.asset(
  'assets/images/logo.png',
  height: 64,
  width: 64,
  fit: BoxFit.contain,
),
            title: 'Admin sign-in',
            subtitle: 'Enter your credentials. We will email you a 6-digit '
                'code to finish signing in.',
            children: [
              if (state.authState.errorMessage != null) ...[
                AuthNotice(
                  message: state.authState.errorMessage!,
                  isError: true,
                ),
                const SizedBox(height: 20),
              ],
              AuthTextField(
                controller: _emailController,
                hint: 'Email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                onFieldSubmitted: (_) => _submit(context),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              AuthSubmitButton(
                label: 'Continue',
                isLoading: state.authState.isLoading,
                onPressed: () => _submit(context),
              ),
              const SizedBox(height: 20),
              const Text(
                'Admin accounts are created by the PHolders team. '
                'There is no self-registration.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
