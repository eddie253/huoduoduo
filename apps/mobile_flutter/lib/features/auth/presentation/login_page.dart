import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../application/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const Key accountFieldKey = Key('login.accountField');
  static const Key passwordFieldKey = Key('login.passwordField');
  static const Key submitButtonKey = Key('login.submitButton');

  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final account = _accountController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final session = await ref.read(authControllerProvider.notifier).login(
            account: account,
            password: password,
            platform: Theme.of(context).platform == TargetPlatform.iOS
                ? 'ios'
                : 'android',
          );
      if (!mounted) {
        return;
      }
      context.go('/webview', extra: session.webviewBootstrap);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is Exception
          ? error.toString().replaceFirst('Exception: ', '')
          : '登入失敗，請稍後再試。';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _exitApp() async {
    await SystemNavigator.pop();
  }

  Future<void> _openExternal(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法開啟連結。')),
      );
    }
  }

  Widget _legacyInput({
    Key? fieldKey,
    required TextEditingController controller,
    required String hintText,
    required String iconAsset,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    ValueChanged<String>? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = colors.primary;

    return TextFormField(
      key: fieldKey,
      controller: controller,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: colors.surface.withValues(alpha: 0.96),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Image.asset(
            iconAsset,
            width: 18,
            height: 18,
          ),
        ),
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
                tooltip: obscureText ? '顯示密碼' : '隱藏密碼',
                onPressed: onToggleObscure,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.outlineVariant, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _primaryAction({
    Key? key,
    required String text,
    required IconData icon,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return FilledButton.icon(
      key: key,
      onPressed: onPressed,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(text),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _secondaryAction({
    required String text,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: colors.onSurface,
        side: BorderSide(color: colors.outlineVariant, width: 1.2),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/legacy_login/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.white.withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.06),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Form(
                key: _formKey,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 28),
                        Image.asset(
                          'assets/legacy_login/img_welcome.png',
                          width: 320,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '貨多多物流',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '請輸入使用者帳號及密碼',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                          decoration: BoxDecoration(
                            color: colors.surface.withValues(alpha: 0.86),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color:
                                  colors.outlineVariant.withValues(alpha: 0.65),
                              width: 1.2,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: colors.shadow.withValues(alpha: 0.16),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: <Widget>[
                              _legacyInput(
                                fieldKey: accountFieldKey,
                                controller: _accountController,
                                textInputAction: TextInputAction.next,
                                autofillHints: const <String>[
                                  AutofillHints.username,
                                ],
                                hintText: '帳號',
                                iconAsset: 'assets/legacy_login/user.png',
                                validator: (String? value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '請輸入帳號';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _legacyInput(
                                fieldKey: passwordFieldKey,
                                controller: _passwordController,
                                textInputAction: TextInputAction.done,
                                autofillHints: const <String>[
                                  AutofillHints.password,
                                ],
                                hintText: '密碼',
                                iconAsset: 'assets/legacy_login/password.png',
                                obscureText: _obscurePassword,
                                onFieldSubmitted: (_) => _submit(),
                                onToggleObscure: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                validator: (String? value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '請輸入密碼';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              _primaryAction(
                                text: isLoading ? '登入中...' : '登入',
                                icon: Icons.login_rounded,
                                onPressed: isLoading ? null : _submit,
                                loading: isLoading,
                                key: submitButtonKey,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _secondaryAction(
                                      text: '註冊',
                                      icon: Icons.person_add_alt_1_rounded,
                                      onPressed: () =>
                                          _openExternal(AppConfig.registerUrl),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _secondaryAction(
                                      text: '忘記密碼',
                                      icon: Icons.lock_reset_rounded,
                                      onPressed: () => _openExternal(
                                        AppConfig.resetPasswordUrl,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _exitApp,
                                icon:
                                    const Icon(Icons.logout_rounded, size: 18),
                                label: const Text('離開'),
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.onSurfaceVariant,
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Image.asset(
                          'assets/legacy_login/boss.png',
                          width: 320,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
