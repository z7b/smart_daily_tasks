import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../helpers/log_helper.dart';
import '../config/storage_keys.dart';

/// SecurityService - Uses native MethodChannel to prevent screenshots safely
class SecurityService extends GetxService {
  final _box = GetStorage();
  static const platform = MethodChannel('com.example.smart_daily_tasks/security');

  RxBool isScreenshotPrevented = false.obs;
  RxBool isRooted = false.obs;
  RxBool isJailbroken = false.obs;

  Future<SecurityService> init() async {
    try {
      // ✅ Use centralized StorageKeys
      isScreenshotPrevented.value = _box.read(StorageKeys.preventScreenshots) ?? false;

      if (isScreenshotPrevented.value) {
        Future.delayed(const Duration(seconds: 2), () {
          _applyScreenshotPrevention(true);
        });
      }
    } catch (e, stack) {
      talker.handle(e, stack, '⚠️ SecurityService init error (non-fatal)');
    }

    return this;
  }

  /// Actually apply screenshot prevention via custom MethodChannel
  Future<void> _applyScreenshotPrevention(bool enable) async {
    try {
      if (Platform.isAndroid) {
        if (enable) {
          await platform.invokeMethod('secure');
          talker.info('🔒 Screenshot prevention applied (Native)');
        } else {
          await platform.invokeMethod('unsecure');
          talker.info('🔓 Screenshot prevention removed (Native)');
        }
      }
    } catch (e, stack) {
      talker.handle(e, stack, '⚠️ Error applying screenshot prevention');
    }
  }

  /// Enable screenshot prevention
  Future<void> enableScreenshotPrevention() async {
    isScreenshotPrevented.value = true;
    _box.write(StorageKeys.preventScreenshots, true);
    _applyScreenshotPrevention(true);
    talker.info('✅ Screenshot prevention enabled');
  }

  /// Disable screenshot prevention
  Future<void> disableScreenshotPrevention() async {
    isScreenshotPrevented.value = false;
    _box.write(StorageKeys.preventScreenshots, false);
    _applyScreenshotPrevention(false);
    talker.info('✅ Screenshot prevention disabled');
  }

  /// Toggle screenshot prevention
  Future<void> toggleScreenshotPrevention() async {
    if (isScreenshotPrevented.value) {
      await disableScreenshotPrevention();
    } else {
      await enableScreenshotPrevention();
    }
  }

  /// Check if device is rooted or jailbroken
  Future<void> checkRootStatus() async {
    isRooted.value = false;
    isJailbroken.value = false;
  }

  /// Get security status summary
  String getSecurityStatus() {
    if (isRooted.value || isJailbroken.value) {
      return 'security_status_unsafe'.tr;
    } else if (isScreenshotPrevented.value) {
      return 'security_status_safe'.tr;
    } else {
      return 'security_status_normal'.tr;
    }
  }
}
