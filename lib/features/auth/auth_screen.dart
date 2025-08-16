import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/auth_service.dart';
import '../../navigation/main_nav_shell.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authProvider.notifier);
      
      if (_isLogin) {
        await authNotifier.loginWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await authNotifier.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      // Navigate to main app on success
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavShell()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode 
            ? AppColors.darkGradient 
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  AppColors.primaryLight.withValues(alpha: 0.05),
                  AppColors.primaryLight.withValues(alpha: 0.1),
                ],
              ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Spacer(),
                  
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 3,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: SvgPicture.asset(
                      'assets/Einwegpfandsymbol-Austria 1.svg',
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // App Name
                  Text(
                    'Pfandler',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.primaryLight,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.sm),
                  
                  Text(
                    _isLogin ? 'Welcome back!' : 'Create your account',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDarkMode 
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textSecondaryLight,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(CupertinoIcons.mail),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                      filled: true,
                      fillColor: isDarkMode 
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.8),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(CupertinoIcons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                      filled: true,
                      fillColor: isDarkMode 
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.8),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (!_isLogin && value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Auth Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.md),
                        ),
                        elevation: 3,
                      ),
                      child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isLogin ? 'Sign In' : 'Sign Up',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Toggle Auth Mode
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin 
                        ? 'Don\'t have an account? Sign up'
                        : 'Already have an account? Sign in',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : AppColors.primaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}