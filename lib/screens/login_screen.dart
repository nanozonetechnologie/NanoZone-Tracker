import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:exptrackerforhybridos/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  bool _isAuthenticating = false;
  String _authMessage = 'Please authenticate to continue';
  bool _canCheckBiometrics = false;
  bool _securityNotAvailable = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometrics();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openSecuritySettings() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.security_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Set Up Screen Lock'),
          ],
        ),
        content: Text(
          'This app requires a screen lock (PIN, pattern, password, or biometric) to be set up on your device for security.\n\n'
          'Please go to your device Settings > Security > Screen Lock and set up a screen lock method.\n\n'
          'After setting it up, come back and tap "I\'ve Set It Up".',
          style: AppTheme.bodyMedium.copyWith(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            height: 1.6,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics = false;
    bool securityNotAvailable = false;

    try {
      // Check if device supports biometrics
      final isDeviceSupported = await _localAuthentication.isDeviceSupported();
      canCheckBiometrics = await _localAuthentication.canCheckBiometrics;

      if (canCheckBiometrics) {
        // Check if any biometrics are enrolled
        final availableBiometrics = await _localAuthentication.getAvailableBiometrics();
        debugPrint('Available biometrics: $availableBiometrics');
      }

      canCheckBiometrics = canCheckBiometrics || isDeviceSupported;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometrics: $e');
      // Check if error is due to no security credentials
      if (e.code == 'NotAvailable' || e.message?.contains('Security credentials') == true) {
        securityNotAvailable = true;
      }
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
    }

    if (!mounted) return;

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
      _securityNotAvailable = securityNotAvailable;
    });

    if (securityNotAvailable) {
      setState(() {
        _authMessage = 'No screen lock detected on this device';
      });
    } else if (canCheckBiometrics) {
      // Wait longer before showing authentication dialog to ensure UI is fully rendered
      // This prevents "Skipped frames" issue and ensures smooth animations
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        _authenticate();
      }
    } else {
      setState(() {
        _authMessage = 'Biometric authentication is not available on this device';
      });
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating || !mounted) return;

    setState(() {
      _isAuthenticating = true;
      _authMessage = 'Authenticating...';
    });

    // Add a small delay to ensure UI is stable before showing auth dialog
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    bool authenticated = false;
    try {
      authenticated = await _localAuthentication.authenticate(
        localizedReason: 'Please authenticate to access NanoZone Budget Tracker',
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow PIN/Pattern as fallback
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true, // Reduces focus changes and buffer issues
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Authentication error: $e');
      if (!mounted) return;

      // Handle specific error codes
      if (e.code == 'NotAvailable' || e.message?.contains('Security credentials') == true) {
        setState(() {
          _securityNotAvailable = true;
          _canCheckBiometrics = false;
          _authMessage = 'No screen lock detected on this device';
          _isAuthenticating = false;
        });
        return;
      } else if (e.code == 'NotEnrolled') {
        setState(() {
          _authMessage = 'No biometrics enrolled. Please set up biometrics in device settings.';
        });
      } else if (e.code == 'auth_in_progress') {
        // Authentication already in progress, just return
        setState(() {
          _isAuthenticating = false;
          _authMessage = 'Please complete the authentication';
        });
        return;
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        setState(() {
          _authMessage = 'Too many attempts. Please try again later.';
        });
      } else {
        setState(() {
          _authMessage = 'Authentication required to access the app';
        });
      }
    } catch (e) {
      debugPrint('Authentication error: $e');
      if (!mounted) return;
      setState(() {
        _authMessage = 'Authentication required to access the app';
      });
    }

    if (!mounted) return;

    setState(() {
      _isAuthenticating = false;
    });

    if (authenticated) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      if (!mounted) return;
      setState(() {
        _authMessage = 'Tap the fingerprint to authenticate';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppTheme.backgroundDark,
                    AppTheme.primaryDarkColor.withAlpha(30),
                  ]
                : [
                    AppTheme.backgroundLight,
                    AppTheme.primaryColor.withAlpha(8),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Logo Section
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppTheme.primaryGradient,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withAlpha(50),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(29),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(29),
                      child: Image.asset(
                        'assets/app_logo.png',
                        width: 114,
                        height: 114,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'NanoZone Budget',
                  style: AppTheme.heading2.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Secure • Simple • Smart',
                  style: AppTheme.bodyMedium.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),

                // Authentication Section
                if (_isAuthenticating)
                  _buildLoadingState(isDark)
                else if (_canCheckBiometrics)
                  _buildAuthState(isDark)
                else if (_securityNotAvailable)
                  _buildSecurityNotAvailable(isDark)
                else
                  _buildBiometricsNotAvailable(isDark),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Column(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AppTheme.primaryLightColor : AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _authMessage,
          style: AppTheme.bodyLarge.copyWith(
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAuthState(bool isDark) {
    return Column(
      children: [
        // Fingerprint Button with Pulse Animation
        ScaleTransition(
          scale: _pulseAnimation,
          child: GestureDetector(
            onTap: _authenticate,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withAlpha(25),
                    AppTheme.primaryColor.withAlpha(10),
                  ],
                ),
                border: Border.all(
                  color: AppTheme.primaryColor.withAlpha(80),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withAlpha(20),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.fingerprint_rounded,
                size: 64,
                color: isDark ? AppTheme.primaryLightColor : AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _authMessage,
          textAlign: TextAlign.center,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap the fingerprint to authenticate',
          textAlign: TextAlign.center,
          style: AppTheme.bodyMedium.copyWith(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityNotAvailable(bool isDark) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.errorColor.withAlpha(15),
            border: Border.all(
              color: AppTheme.errorColor.withAlpha(50),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.lock_open_rounded,
            size: 48,
            color: AppTheme.errorColor,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          _authMessage,
          textAlign: TextAlign.center,
          style: AppTheme.heading4.copyWith(
            color: AppTheme.errorColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'This app requires a screen lock for security.',
          textAlign: TextAlign.center,
          style: AppTheme.bodyMedium.copyWith(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set up: PIN • Pattern • Password • Biometric',
          textAlign: TextAlign.center,
          style: AppTheme.caption.copyWith(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openSecuritySettings,
            icon: const Icon(Icons.settings_rounded),
            label: const Text('How to Set Up'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _securityNotAvailable = false;
              });
              _checkBiometrics();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('I\'ve Set It Up'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricsNotAvailable(bool isDark) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.warningColor.withAlpha(15),
            border: Border.all(
              color: AppTheme.warningColor.withAlpha(50),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: AppTheme.warningColor,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          _authMessage,
          textAlign: TextAlign.center,
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.warningColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Please enable biometric authentication in your device settings.',
          textAlign: TextAlign.center,
          style: AppTheme.bodyMedium.copyWith(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _checkBiometrics,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Check Again'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
      ],
    );
  }
}
