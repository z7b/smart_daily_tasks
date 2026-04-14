import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../helpers/bottom_sheet_helper.dart';
import '../helpers/log_helper.dart';
import '../config/storage_keys.dart';

class AppLockService extends GetxService {
  final _box = GetStorage();
  final _localAuth = LocalAuthentication();

  RxBool isAppLockEnabled = false.obs;
  RxBool isBiometricAvailable = false.obs;
  RxBool isBiometricEnabled = false.obs;

  Future<AppLockService> init() async {
    try {
      isAppLockEnabled.value = _box.read(StorageKeys.appLockEnabled) ?? false;
      isBiometricEnabled.value = _box.read(StorageKeys.biometricEnabled) ?? false;
      Future.delayed(const Duration(seconds: 1), () => checkBiometricAvailability());
    } catch (e, stack) {
      talker.handle(e, stack, '⚠️ AppLockService init error');
    }
    return this;
  }

  String _preparePin(String pin) => pin.trim();

  Future<void> checkBiometricAvailability() async {
    try {
      isBiometricAvailable.value = await _localAuth.canCheckBiometrics;
    } catch (e) {
      isBiometricAvailable.value = false;
    }
  }

  Future<bool> authenticate() async {
    try {
      if (isBiometricEnabled.value && isBiometricAvailable.value) {
        return await _authenticateWithBiometric();
      }
      return await _authenticateWithPin();
    } catch (e) {
      return false;
    }
  }

  Future<bool> _authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'authenticate_to_unlock'.tr,
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> _authenticateWithPin() async {
    final savedPin = _box.read<String>(StorageKeys.pinHash);
    if (savedPin == null) return false;

    final pinController = TextEditingController();
    final pinFocusNode = FocusNode();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (pinFocusNode.canRequestFocus) pinFocusNode.requestFocus();
    });

    final result = await BottomSheetHelper.showSafeBottomSheet<bool>(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('enter_pin'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: pinController,
                focusNode: pinFocusNode,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 10),
                decoration: InputDecoration(
                  hintText: '****',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onSubmitted: (val) {
                  if (_preparePin(val) == savedPin) Get.back(result: true);
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_preparePin(pinController.text) == savedPin) {
                      Get.back(result: true);
                    } else {
                      Get.snackbar('error'.tr, 'pin_mismatch'.tr);
                    }
                  },
                  child: Text('confirm'.tr),
                ),
              ),
            ],
          ),
        );
      },
    );
    
    pinFocusNode.dispose();
    pinController.dispose();
    return result ?? false;
  }

  Future<void> toggleAppLock() async {
    if (isAppLockEnabled.value) {
      // Deactivating: needs authentication
      final authenticated = await authenticate();
      if (authenticated) {
        isAppLockEnabled.value = false;
        _box.write(StorageKeys.appLockEnabled, false);
        Get.snackbar('success'.tr, 'app_lock_disabled_msg'.tr);
      }
    } else {
      // Activating: needs PIN setup
      await _showSetupDialog();
    }
  }

  Future<void> _showSetupDialog() async {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();
    final pinFocusNode = FocusNode();
    final confirmPinFocusNode = FocusNode();

    try {
      // Small delay to ensure BottomSheet is ready for focus
      Future.delayed(const Duration(milliseconds: 500), () {
        if (pinFocusNode.canRequestFocus) pinFocusNode.requestFocus();
      });

      await BottomSheetHelper.showSafeBottomSheet(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('setup_pin'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: pinController,
                  focusNode: pinFocusNode,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, letterSpacing: 8),
                  decoration: InputDecoration(
                    labelText: 'enter_pin'.tr,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: (_) => confirmPinFocusNode.requestFocus(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPinController,
                  focusNode: confirmPinFocusNode,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, letterSpacing: 8),
                  decoration: InputDecoration(
                    labelText: 'confirm_pin'.tr,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: (_) {
                    if (pinController.text == confirmPinController.text) {
                      _enableAppLock(pin: pinController.text).then((_) => Get.back());
                    }
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (pinController.text.length >= 4 && pinController.text == confirmPinController.text) {
                        await _enableAppLock(pin: pinController.text);
                        Get.back();
                      } else {
                        Get.snackbar('error'.tr, 'pin_mismatch'.tr);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('save'.tr),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      pinFocusNode.dispose();
      confirmPinFocusNode.dispose();
      pinController.dispose();
      confirmPinController.dispose();
      talker.info('🔒 PIN Setup dialog resources disposed');
    }
  }

  Future<void> _enableAppLock({required String pin}) async {
    _box.write(StorageKeys.pinHash, _preparePin(pin));
    isAppLockEnabled.value = true;
    _box.write(StorageKeys.appLockEnabled, true);
    Get.snackbar('success'.tr, 'app_lock_enabled_msg'.tr);
  }
}
