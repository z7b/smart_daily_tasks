import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:screen_protector/screen_protector.dart';
import '../helpers/log_helper.dart';
import '../config/storage_keys.dart';

class AppLockService extends GetxService {
  final _box = GetStorage();
  final _localAuth = LocalAuthentication();

  RxBool isAppLockEnabled = false.obs;
  RxBool isBiometricAvailable = false.obs;
  RxBool isBiometricEnabled = false.obs;
  RxBool isOverlayVisible = false.obs; // 🚀 Controls the Blur Overlay UI
  RxBool isProtectionPaused = false.obs; // 🛡️ Temporary bypass for system dialogs (e.g. Health Connect)

  Future<AppLockService> init() async {
    try {
      isAppLockEnabled.value = _box.read(StorageKeys.appLockEnabled) ?? false;
      isBiometricEnabled.value = _box.read(StorageKeys.biometricEnabled) ?? false;
      
      // Initialize Screen Protection if enabled
      if (isAppLockEnabled.value) {
        await enablePrivacyProtection();
      }

      Future.delayed(const Duration(seconds: 1), () => checkBiometricAvailability());
    } catch (e, stack) {
      talker.handle(e, stack, '⚠️ AppLockService init error');
    }
    return this;
  }

  Future<void> checkBiometricAvailability() async {
    try {
      isBiometricAvailable.value = await _localAuth.canCheckBiometrics;
    } catch (e) {
      isBiometricAvailable.value = false;
    }
  }

  Future<bool> authenticate() async {
    try {
      // 🛡️ Use Native System Authentication (Device Lock / Biometrics)
      // This will prompt for Fingerprint/FaceID or System PIN/Pattern automatically
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'authenticate_to_unlock_app'.tr,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // 🛡️ Expert Fix: System handles biometric with automatic fallback
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        await hidePrivacyOverlay();
        return true;
      }
      
      return false;
    } catch (e, stack) {
      talker.handle(e, stack, '🔒 Authentication critical error');
      return false;
    }
  }

  // ─── Privacy Overlay Helpers ─────────────────────────────────
  
  Future<void> enablePrivacyProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      talker.info('🔐 Privacy Protection Enabled (Screenshot & Recents hidden)');
    } catch (e) {
      talker.error('⚠️ Failed to enable ScreenProtector: $e');
    }
  }

  Future<void> disablePrivacyProtection() async {
    try {
      await ScreenProtector.preventScreenshotOff();
      talker.info('🔓 Privacy Protection Disabled');
    } catch (e) {
      talker.error('⚠️ Failed to disable ScreenProtector: $e');
    }
  }

  Future<void> showPrivacyOverlay() async {
    isOverlayVisible.value = true;
    await enablePrivacyProtection();
  }

  Future<void> hidePrivacyOverlay() async {
    isOverlayVisible.value = false;
    await disablePrivacyProtection();
  }

  Future<void> toggleAppLock() async {
    // Both activating and deactivating require verification to ensure device owner
    final authenticated = await authenticate();
    
    if (authenticated) {
      isAppLockEnabled.value = !isAppLockEnabled.value;
      _box.write(StorageKeys.appLockEnabled, isAppLockEnabled.value);
      
      if (isAppLockEnabled.value) {
        await enablePrivacyProtection();
        Get.snackbar('success'.tr, 'app_lock_enabled_msg'.tr);
      } else {
        await disablePrivacyProtection();
        Get.snackbar('success'.tr, 'app_lock_disabled_msg'.tr);
      }
    } else {
      // Logic for authentication failure is handled by system dialogs or user cancelation
      talker.warning('🔒 App Lock toggle canceled or failed');
    }
  }

  void toggleBiometric() {
    if (!isBiometricAvailable.value) {
      Get.snackbar('error'.tr, 'biometric_not_available'.tr);
      return;
    }
    isBiometricEnabled.value = !isBiometricEnabled.value;
    _box.write(StorageKeys.biometricEnabled, isBiometricEnabled.value);
    Get.snackbar(
      'security'.tr,
      isBiometricEnabled.value ? 'biometric_enabled'.tr : 'biometric_disabled'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
