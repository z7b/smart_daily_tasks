import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_lock_service.dart';

/// Observer to handle app lifecycle and trigger app lock with focus protection
class AppLockObserver extends WidgetsBindingObserver {
  bool _isInBackground = false;
  bool _isAuthenticating = false;
  
  final _lifecycleThrottle = _ThrottleHelper();

  AppLockService? get _appLockService {
    if (Get.isRegistered<AppLockService>()) {
      return Get.find<AppLockService>();
    }
    return null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final service = _appLockService;
    if (service == null) return;

    switch (state) {
      case AppLifecycleState.inactive:
        // Inactive often means system UI like Keyboard or Biometrics is showing.
        // We do NOT set background here to prevent UI loops.
        debugPrint('🟡 App Inactive (System UI/Transition)');
        break;

      case AppLifecycleState.paused:
        _isInBackground = true;
        debugPrint('🔒 App Paused (In Background)');
        break;

      case AppLifecycleState.resumed:
        if (_isInBackground && service.isAppLockEnabled.value) {
          debugPrint('🔒 App Resumed - Preparing Auth');
          _isInBackground = false;
          
          // ✅ Fix: Add slight delay to allow system to settle before showing lock
          _lifecycleThrottle.throttle(
            () => _showLockScreen(service),
            duration: const Duration(milliseconds: 600),
          );
        } else {
          _isInBackground = false;
        }
        break;

      default:
        break;
    }
  }

  Future<void> _showLockScreen(AppLockService service) async {
    if (_isAuthenticating) return;

    _isAuthenticating = true;

    try {
      // ✅ Critical Fix: Unfocus any active text field before showing lock
      // This prevents the keyboard from conflicting with the auth dialog
      FocusManager.instance.primaryFocus?.unfocus();
      
      await Future.delayed(const Duration(milliseconds: 400));

      if (_isInBackground) {
        _isAuthenticating = false;
        return;
      }

      bool authenticated = await service.authenticate();
      
      if (!authenticated) {
        _showAuthFailureDialog();
      }
    } catch (e) {
      debugPrint('🔴 Lock screen critical error: $e');
    } finally {
      _isAuthenticating = false;
    }
  }

  void _showAuthFailureDialog() {
    if (Get.isDialogOpen ?? false) return;
    
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('خطأ في التحقق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('يرجى إعادة المحاولة لفتح التطبيق.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              if (Get.isDialogOpen ?? false) Get.back();
              _isAuthenticating = false;
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}

class _ThrottleHelper {
  Timer? _timer;
  bool _isThrottled = false;

  void throttle(VoidCallback callback, {required Duration duration}) {
    if (_isThrottled) return;
    _isThrottled = true;
    callback();
    _timer = Timer(duration, () => _isThrottled = false);
  }
  
  void dispose() => _timer?.cancel();
}
