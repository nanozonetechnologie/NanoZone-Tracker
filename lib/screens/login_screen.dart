import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String _authMessage = 'Touch fingerprint sensor to unlock';
  bool _canCheckBiometrics = false;
  bool _securityNotAvailable = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
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

  Future<void> _checkBiometrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLockEnabled = prefs.getBool('security_lock_enabled') ?? true;

      if (!isLockEnabled) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
        return;
      }
    } catch (_) {}

    bool canCheckBiometrics = false;
    bool securityNotAvailable = false;

    try {
      final isDeviceSupported = await _localAuthentication.isDeviceSupported();
      canCheckBiometrics = await _localAuthentication.canCheckBiometrics;

      if (canCheckBiometrics) {
        final availableBiometrics = await _localAuthentication.getAvailableBiometrics();
        debugPrint('Available biometrics: $availableBiometrics');
      }

      canCheckBiometrics = canCheckBiometrics || isDeviceSupported;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometrics: $e');
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
      await Future.delayed(const Duration(milliseconds: 600));
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
      _authMessage = 'Verifying identity...';
    });

    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    bool authenticated = false;
    try {
      authenticated = await _localAuthentication.authenticate(
        localizedReason: 'Authenticate to access NanoZon Budget Tracker',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Authentication error: $e');
      if (!mounted) return;

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
          _authMessage = 'No biometrics enrolled on device';
        });
      } else if (e.code == 'auth_in_progress') {
        setState(() {
          _isAuthenticating = false;
          _authMessage = 'Authentication in progress';
        });
        return;
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        setState(() {
          _authMessage = 'Too many attempts. Try again later.';
        });
      } else {
        setState(() {
          _authMessage = 'Authentication required to enter';
        });
      }
    } catch (e) {
      debugPrint('Authentication error: $e');
      if (!mounted) return;
      setState(() {
        _authMessage = 'Authentication required to enter';
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
        _authMessage = 'Touch fingerprint sensor to unlock';
      });
    }
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
          'Please go to your device Settings > Security > Screen Lock and set up a screen lock method.',
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0B101D),
                    const Color(0xFF141C30),
                    const Color(0xFF0B101D),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFEEF2FF),
                    const Color(0xFFF8FAFC),
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Premium Brand Header
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppTheme.primaryGradient,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withAlpha(60),
                        blurRadius: 36,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => Image.asset(
                            'assets/app_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Nano',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const TextSpan(
                        text: 'Zon',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.secondaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withAlpha(30)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_rounded, size: 14, color: AppTheme.primaryColor),
                      SizedBox(width: 6),
                      Text(
                        'Protected Environment',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Interactive Biometric Lock Section
                if (_isAuthenticating)
                  _buildLoadingState(isDark)
                else if (_canCheckBiometrics)
                  _buildAuthState(isDark)
                else if (_securityNotAvailable)
                  _buildSecurityNotAvailable(isDark)
                else
                  _buildBiometricsNotAvailable(isDark),

                const Spacer(flex: 2),

                // Footer Security Note
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded, size: 13, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '100% Offline • Encrypted On-Device Data',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
        const SizedBox(
          width: 52,
          height: 52,
          child: CircularProgressIndicator(
            strokeWidth: 3.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _authMessage,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
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
        ScaleTransition(
          scale: _pulseAnimation,
          child: GestureDetector(
            onTap: _authenticate,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withAlpha(30),
                    AppTheme.primaryColor.withAlpha(10),
                  ],
                ),
                border: Border.all(
                  color: AppTheme.primaryColor.withAlpha(120),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withAlpha(40),
                    blurRadius: 32,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.fingerprint_rounded,
                size: 72,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _authMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap sensor or icon to scan',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
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
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.errorColor.withAlpha(15),
            border: Border.all(color: AppTheme.errorColor.withAlpha(50), width: 2),
          ),
          child: const Icon(Icons.lock_open_rounded, size: 42, color: AppTheme.errorColor),
        ),
        const SizedBox(height: 24),
        Text(
          _authMessage,
          textAlign: TextAlign.center,
          style: AppTheme.heading4.copyWith(color: AppTheme.errorColor),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openSecuritySettings,
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Set Up Device Screen Lock'),
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricsNotAvailable(bool isDark) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.warningColor.withAlpha(15),
            border: Border.all(color: AppTheme.warningColor.withAlpha(50), width: 2),
          ),
          child: const Icon(Icons.warning_amber_rounded, size: 42, color: AppTheme.warningColor),
        ),
        const SizedBox(height: 24),
        Text(
          _authMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.warningColor),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _checkBiometrics,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ),
      ],
    );
  }
}
