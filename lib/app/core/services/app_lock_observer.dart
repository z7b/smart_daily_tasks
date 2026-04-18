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
        // 🛡️ Privacy Blur Trigger (Transition/App Switcher)
        if (service.isAppLockEnabled.value && !service.isProtectionPaused.value) {
          service.showPrivacyOverlay();
          debugPrint('🟡 App Inactive - Protection Active');
        } else {
          debugPrint('🟢 App Inactive - Protection Paused (Handshake Mode)');
        }
        break;

      case AppLifecycleState.paused:
        _isInBackground = true;
        if (service.isAppLockEnabled.value && !service.isProtectionPaused.value) {
          service.showPrivacyOverlay();
          debugPrint('🔒 App Paused - Locked');
        }
        break;

      case AppLifecycleState.resumed:
        if (_isInBackground && service.isAppLockEnabled.value) {
          _isInBackground = false;
          debugPrint('🔒 App Resumed - Triggering Native Auth');
          
          // Show overlay immediately if it's not already visible
          service.showPrivacyOverlay();

          _lifecycleThrottle.throttle(
            () => _showLockScreen(service),
            duration: const Duration(milliseconds: 500),
          );
        } else {
          _isInBackground = false;
        }
        break;

      default:
        break;
    }
  }

  // ✅ Public trigger for Cold Boot Security
  void enforceColdBootLock() {
    final service = _appLockService;
    if (service != null && service.isAppLockEnabled.value) {
      debugPrint('🔒 Enforcing Cold Boot App Lock');
      _showLockScreen(service);
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
        _showAuthFailureDialog(service);
      }
    } catch (e) {
      debugPrint('🔴 Lock screen critical error: $e');
    } finally {
      _isAuthenticating = false;
    }
  }

  void _showAuthFailureDialog(AppLockService service) {
    if (Get.isDialogOpen ?? false) return;
    
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Text('auth_failure_title'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('auth_failure_msg'.tr, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              if (Get.isDialogOpen ?? false) Get.back();
              _isAuthenticating = false;
              _showLockScreen(service); // Immediately retry authentication
            },
            child: Text('retry'.tr),
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
