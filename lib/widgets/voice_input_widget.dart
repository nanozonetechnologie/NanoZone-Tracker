import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';
import '../helpers/voice_input_helper.dart';

class VoiceInputWidget extends StatefulWidget {
  final Function(VoiceExpenseResult) onResult;
  final VoidCallback? onCancel;

  const VoiceInputWidget({
    super.key,
    required this.onResult,
    this.onCancel,
  });

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _permissionDeniedPermanently = false;
  bool _isProcessing = false;
  String _currentText = '';
  String _statusMessage = 'Checking permissions...';
  double _soundLevel = 0.0;
  
  Timer? _silenceTimer;
  DateTime? _lastResultTime;
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
    _checkAndRequestPermission();
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _animationController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _checkAndRequestPermission() async {
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      _hasPermission = true;
      await _initSpeech();
      return;
    }

    if (status.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _permissionDeniedPermanently = true;
          _statusMessage = 'Microphone permission denied';
        });
      }
      _showPermissionDeniedDialog();
      return;
    }

    if (mounted) {
      await _showPermissionExplanationDialog();
    }
  }

  Future<void> _showPermissionExplanationDialog() async {
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mic, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Flexible(child: Text('Microphone Permission')),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voice input requires microphone access to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Listen to your voice commands')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Convert speech to expense entries')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Add expenses hands-free')),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Your voice data is processed locally and not stored.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    if (shouldRequest == true) {
      await _requestPermission();
    } else {
      if (mounted) {
        setState(() {
          _statusMessage = 'Permission required for voice input';
        });
      }
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      _hasPermission = true;
      await _initSpeech();
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _permissionDeniedPermanently = true;
          _statusMessage = 'Microphone permission denied';
        });
      }
      _showPermissionDeniedDialog();
    } else {
      if (mounted) {
        setState(() {
          _statusMessage = 'Microphone permission denied';
        });
      }
    }
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Flexible(child: Text('Permission Required')),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Microphone permission is required for voice input feature.',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 16),
            Text(
              'Please enable microphone permission in app settings to use voice commands.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _initSpeech() async {
    if (!_hasPermission) {
      if (mounted) setState(() => _statusMessage = 'Microphone permission required');
      return;
    }

    try {
      // Cancel any ongoing session before re-init
      await _speech.cancel();
      
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            _handleStop();
          }
        },
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          if (!mounted) return;
          
          if (error.errorMsg == 'error_speech_timeout') {
            _handleStop();
          } else {
            setState(() {
              _isListening = false;
              _statusMessage = 'Assistant busy. Tap to retry.';
            });
          }
          _silenceTimer?.cancel();
        },
        debugLogging: false,
      );

      if (mounted) {
        setState(() => _statusMessage = _isInitialized ? 'Ready to listen' : 'Speech not available');
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = 'Failed to initialize');
    }
  }

  void _handleStop() {
    if (!_isListening) return;
    
    setState(() {
      _isListening = false;
      if (_currentText.isNotEmpty) {
        _statusMessage = 'Understanding...';
        _processVoiceInput();
      } else {
        _statusMessage = 'Tap to try again';
      }
    });
    _silenceTimer?.cancel();
  }

  void _startListening() async {
    if (!_hasPermission) {
      await _checkAndRequestPermission();
      return;
    }

    if (!_isInitialized) {
      await _initSpeech();
      if (!_isInitialized) return;
    }

    if (mounted) {
      setState(() {
        _isListening = true;
        _currentText = '';
        _statusMessage = 'Listening...';
        _lastResultTime = DateTime.now();
      });
    }

    // Start silence detection timer
    _silenceTimer?.cancel();
    _silenceTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_lastResultTime != null) {
        final silenceDuration = DateTime.now().difference(_lastResultTime!);
        // If 1.5 seconds of silence after some words, auto-stop
        if (_currentText.isNotEmpty && silenceDuration.inMilliseconds >= 1500) {
          _stopListening();
        } 
        // If 5 seconds of silence with no words, auto-stop
        else if (_currentText.isEmpty && silenceDuration.inSeconds >= 5) {
          _stopListening();
        }
      }
    });

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (!mounted) return;
        setState(() {
          _currentText = result.recognizedWords;
          _lastResultTime = DateTime.now();
          if (result.finalResult) {
            _handleStop();
          }
        });
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() => _soundLevel = level);
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
        autoPunctuation: true,
      ),
      // ignore: deprecated_member_use
      localeId: 'en_IN',
    );
  }

  void _stopListening() async {
    _silenceTimer?.cancel();
    await _speech.stop();
    _handleStop();
  }

  void _processVoiceInput() {
    if (_currentText.isEmpty || _isProcessing) return;
    
    _isProcessing = true;
    final result = VoiceInputHelper.parseVoiceInput(_currentText);
    
    // Provide a small visual confirmation if successful
    if (result.isValid) {
      setState(() => _statusMessage = 'Intent identified!');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onResult(result);
      });
    } else {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Could not understand. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(child: Text('🎤 Voice Assistant', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
                IconButton(
                  icon: const Icon(Icons.close_rounded), 
                  onPressed: () {
                    _speech.stop();
                    _silenceTimer?.cancel();
                    if (widget.onCancel != null) widget.onCancel!();
                  }
                ),
              ],
            ),
            const SizedBox(height: 32),

          if (_permissionDeniedPermanently) ...[
            _buildPermissionDeniedView(),
          ] else ...[
            _buildMicButton(),
            const SizedBox(height: 16),
            Text(_statusMessage, style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            const SizedBox(height: 32),
            _buildResultPreview(),
            const SizedBox(height: 24),
            _buildExampleCommands(),
            const SizedBox(height: 24),
            if (_currentText.isNotEmpty && !_isListening && !_isProcessing)
              _buildAddButton(),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _isListening ? _stopListening : _startListening,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Transform.scale(
          scale: _isListening ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isListening 
                  ? [Colors.red, Colors.redAccent] 
                  : (_hasPermission ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)] : [Colors.grey, Colors.grey]),
              ),
              boxShadow: [BoxShadow(
                color: (_isListening ? Colors.red : const Color(0xFF6366F1)).withAlpha(102),
                blurRadius: _isListening ? 30 + (_soundLevel * 3) : 15,
                spreadRadius: _isListening ? 8 + _soundLevel : 4,
              )],
            ),
            child: Icon(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded, size: 54, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildResultPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withAlpha(5) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
        border: _isListening ? Border.all(color: const Color(0xFF6366F1).withAlpha(100), width: 2) : null,
      ),
      constraints: const BoxConstraints(minHeight: 100),
      child: Text(
        _currentText.isEmpty ? 'Try saying:\n"I spent 1200 on fuel today"' : _currentText,
        style: TextStyle(
          fontSize: 18,
          color: _currentText.isEmpty ? Colors.grey : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
          fontStyle: _currentText.isEmpty ? FontStyle.italic : FontStyle.normal,
          fontWeight: _currentText.isEmpty ? FontWeight.normal : FontWeight.w600,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildExampleCommands() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('HINTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip('Add 500 for lunch'),
            _buildChip('Spent 2k on shopping'),
            _buildChip('Petrol 1500 via UPI'),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _processVoiceInput,
        icon: const Icon(Icons.check_circle_rounded),
        label: const Text('Identify & Add'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withAlpha(50)),
      ),
      child: Column(
        children: [
          const Icon(Icons.mic_off_rounded, size: 54, color: Colors.orange),
          const SizedBox(height: 16),
          const Text('Microphone Access Required', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('To use voice commands, please enable microphone access in your system settings.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

Future<VoiceExpenseResult?> showVoiceInputSheet(BuildContext context) async {
  VoiceExpenseResult? result;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (ctx) => VoiceInputWidget(
      onResult: (voiceResult) { 
        result = voiceResult; 
        if (ctx.mounted) Navigator.of(ctx).pop(); 
      },
      onCancel: () {
        if (ctx.mounted) Navigator.of(ctx).pop();
      },
    ),
  );
  return result;
}
