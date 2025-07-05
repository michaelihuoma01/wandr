import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class EnhancedAuthScreen extends StatefulWidget {
  const EnhancedAuthScreen({super.key});

  @override
  State<EnhancedAuthScreen> createState() => _EnhancedAuthScreenState();
}

class _EnhancedAuthScreenState extends State<EnhancedAuthScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();

  bool _isSignIn = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showPasswordStrength = false;
  String? _errorMessage;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignIn = !_isSignIn;
      _errorMessage = null;
      _showPasswordStrength = !_isSignIn;
    });
    
    _slideController.reset();
    _slideController.forward();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      AuthResult result;

      if (_isSignIn) {
        result = await _authService.signInWithEmail(
          email: email,
          password: password,
        );
      } else {
        final name = _nameController.text.trim();
        result = await _authService.signUpWithEmail(
          email: email,
          password: password,
          name: name,
        );
      }

      if (result.success) {
        _handleAuthSuccess(result);
      } else {
        setState(() {
          _errorMessage = result.error;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.signInWithGoogle();
      
      if (result.success) {
        _handleAuthSuccess(result);
      } else {
        setState(() {
          _errorMessage = result.error;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleAuthSuccess(AuthResult result) {
    // Navigate based on whether user needs onboarding
    if (result.isNewUser) {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email address to receive a password reset link.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !_authService.isValidEmail(email)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid email address')),
                );
                return;
              }

              Navigator.of(context).pop();
              
              final result = await _authService.sendPasswordResetEmail(email);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.success 
                      ? 'Password reset email sent!' 
                      : result.error ?? 'Failed to send reset email'),
                    backgroundColor: result.success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(String password) {
    final validation = _authService.validatePassword(password);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              validation.isValid ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: validation.isValid ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              'Password Strength',
              style: TextStyle(
                fontSize: 12,
                color: validation.isValid ? Colors.green : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: _calculatePasswordStrength(validation),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            _getPasswordStrengthColor(validation),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildRequirementChip('8+ chars', validation.hasMinLength),
            _buildRequirementChip('A-Z', validation.hasUppercase),
            _buildRequirementChip('a-z', validation.hasLowercase),
            _buildRequirementChip('0-9', validation.hasNumber),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirementChip(String label, bool isValid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? Colors.green : Colors.grey,
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isValid ? Colors.green.shade700 : Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  double _calculatePasswordStrength(PasswordValidation validation) {
    int score = 0;
    if (validation.hasMinLength) score++;
    if (validation.hasUppercase) score++;
    if (validation.hasLowercase) score++;
    if (validation.hasNumber) score++;
    return score / 4.0;
  }

  Color _getPasswordStrengthColor(PasswordValidation validation) {
    final strength = _calculatePasswordStrength(validation);
    if (strength >= 0.75) return Colors.green;
    if (strength >= 0.5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Card(
                    elevation: 8,
                    shadowColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildForm(),
                          const SizedBox(height: 24),
                          _buildActionButtons(),
                          const SizedBox(height: 20),
                          _buildDivider(),
                          const SizedBox(height: 20),
                          _buildGoogleSignIn(),
                          const SizedBox(height: 24),
                          _buildAuthModeToggle(),
                        ],
                      ),
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

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.explore,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome to Wandr',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isSignIn 
            ? 'Sign in to discover your vibe tribe'
            : 'Join the community of explorers',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (!_isSignIn) ...[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) => _clearError(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _clearError(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email address';
              }
              if (!_authService.isValidEmail(value.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onChanged: (value) {
              _clearError();
              if (!_isSignIn && value.isNotEmpty) {
                setState(() {
                  _showPasswordStrength = true;
                });
              }
            },
            onFieldSubmitted: (_) => _handleEmailAuth(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (!_isSignIn) {
                final validation = _authService.validatePassword(value);
                if (!validation.isValid) {
                  return 'Password must be at least 8 characters with uppercase, lowercase, and number';
                }
              }
              return null;
            },
          ),
          if (_showPasswordStrength && !_isSignIn && _passwordController.text.isNotEmpty)
            _buildPasswordStrengthIndicator(_passwordController.text),
          if (_isSignIn) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isSignIn ? 'Sign In' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildGoogleSignIn() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleAuth,
        icon: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: const Icon(
            Icons.g_mobiledata,
            size: 16,
            color: Colors.red,
          ),
        ),
        label: Text(
          'Continue with Google',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAuthModeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignIn 
            ? "Don't have an account? " 
            : "Already have an account? ",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: _toggleAuthMode,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            _isSignIn ? 'Sign Up' : 'Sign In',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}