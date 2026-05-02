import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../../core/services/assistant/ai_provider_config.dart';
import '../controllers/assistant_settings_form_controller.dart';

/// 🏗️ AI Assistant Settings Page
///
/// Architecture:
/// - Uses `GetView<SettingsController>` for backend state (save, test, analytics)
/// - Injects AssistantSettingsFormController for all UI/form state
/// - Full form validation with inline error messages
/// - Custom URL section with animated visibility
/// - Tools toggle with description
/// - Provider-aware field visibility
class AssistantSettingsView extends StatelessWidget {
  const AssistantSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    // 🛡️ fenix: true → controller survives navigating away and back,
    // preserving any unsaved edits the user made (e.g. clearing the API key).
    // Without this, Get.put() would recreate the controller on each visit
    // and reload the old saved values, discarding the user's changes.
    Get.lazyPut(() => AssistantSettingsFormController(), fenix: true);
    final formCtrl = Get.find<AssistantSettingsFormController>();
    final settingsCtrl = Get.find<SettingsController>();
    final theme = Theme.of(context);
    final isAr = Get.locale?.languageCode == 'ar';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _AppBar(theme: theme),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Analytics dashboard
              _AnalyticsDashboard(settingsCtrl: settingsCtrl, theme: theme),
              const SizedBox(height: 24),

              // 2. Provider selector
              _SectionLabel(label: 'ai_provider'.tr, theme: theme),
              const SizedBox(height: 8),
              _ProviderDropdown(settingsCtrl: settingsCtrl, theme: theme),
              const SizedBox(height: 24),

              // 3. Dynamic fields based on selected provider
              Obx(() {
                final provider = settingsCtrl.activeAiProvider;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // API Key
                    if (provider.requiresApiKey) ...[
                      _SectionLabel(label: 'api_key_label'.tr, theme: theme),
                      const SizedBox(height: 8),
                      _ApiKeyField(formCtrl: formCtrl, provider: provider, theme: theme),
                      const SizedBox(height: 20),
                    ],

                    // Model
                    if (provider.requiresModel) ...[
                      _SectionLabel(label: 'model_label'.tr, theme: theme),
                      const SizedBox(height: 8),
                      _ModelField(
                        formCtrl: formCtrl,
                        settingsCtrl: settingsCtrl,
                        provider: provider,
                        theme: theme,
                        isAr: isAr,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Custom URL toggle + field
                    _CustomUrlSection(
                      formCtrl: formCtrl,
                      theme: theme,
                    ),
                    const SizedBox(height: 20),

                    // Tools toggle
                    _ToolsToggle(formCtrl: formCtrl, theme: theme),
                    const SizedBox(height: 32),

                    // Action buttons
                    _ActionButtons(
                      formCtrl: formCtrl,
                      settingsCtrl: settingsCtrl,
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AppBar ────────────────────────────────────────────

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final ThemeData theme;
  const _AppBar({required this.theme});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary, size: 20),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'ai_assistant_settings'.tr,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.textTheme.titleLarge?.color,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    );
  }
}

// ─── Analytics Dashboard ───────────────────────────────

class _AnalyticsDashboard extends StatelessWidget {
  final SettingsController settingsCtrl;
  final ThemeData theme;
  const _AnalyticsDashboard({required this.settingsCtrl, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'total_calls'.tr,
            value: settingsCtrl.aiTotalRequests.value.toString(),
            icon: Icons.analytics_outlined,
            color: Colors.blue,
          ),
          _Divider(),
          _StatItem(
            label: 'latency'.tr,
            value: settingsCtrl.aiLastResponseTime.value,
            icon: Icons.timer_outlined,
            color: Colors.orange,
          ),
          _Divider(),
          _StatItem(
            label: 'status'.tr,
            value: settingsCtrl.aiLastStatus.value.tr,
            icon: _statusIcon(settingsCtrl.aiLastStatus.value),
            color: _statusColor(settingsCtrl.aiLastStatus.value),
          ),
        ],
      ),
    ));
  }

  IconData _statusIcon(String s) {
    if (s == 'success') return Icons.check_circle_outline;
    if (s == 'error') return Icons.error_outline;
    if (s == 'testing') return Icons.hourglass_empty;
    return Icons.radio_button_unchecked;
  }

  Color _statusColor(String s) {
    if (s == 'success') return Colors.green;
    if (s == 'error') return Colors.red;
    if (s == 'testing') return Colors.orange;
    return Colors.grey;
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: VerticalDivider(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        thickness: 1,
      ),
    );
  }
}

// ─── Section Label ─────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final ThemeData theme;
  const _SectionLabel({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
      ),
    );
  }
}

// ─── Provider Dropdown ─────────────────────────────────

class _ProviderDropdown extends StatelessWidget {
  final SettingsController settingsCtrl;
  final ThemeData theme;
  const _ProviderDropdown({required this.settingsCtrl, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: settingsCtrl.aiProviderId.value,
          isExpanded: true,
          icon: Icon(Icons.expand_more_rounded, color: AppTheme.primary),
          items: AiProviderConfig.providers.map((p) => DropdownMenuItem(
            value: p.type.name,
            child: Row(
              children: [
                _ProviderIcon(type: p.type),
                const SizedBox(width: 10),
                Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          )).toList(),
          onChanged: (val) {
            if (val != null) settingsCtrl.changeAiProvider(val);
          },
        ),
      ),
    ));
  }
}

class _ProviderIcon extends StatelessWidget {
  final AiProviderType type;
  const _ProviderIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (type) {
      AiProviderType.openai     => (Icons.auto_awesome, Colors.green),
      AiProviderType.gemini     => (Icons.diamond_outlined, Colors.blue),
      AiProviderType.anthropic  => (Icons.psychology_outlined, Colors.orange),
      AiProviderType.openrouter => (Icons.hub_outlined, Colors.purple),
      AiProviderType.lmStudio   => (Icons.computer_outlined, Colors.teal),
      AiProviderType.ollama     => (Icons.memory_outlined, Colors.indigo),
    };

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

// ─── API Key Field ─────────────────────────────────────

class _ApiKeyField extends StatelessWidget {
  final AssistantSettingsFormController formCtrl;
  final AiProviderConfig provider;
  final ThemeData theme;
  const _ApiKeyField({required this.formCtrl, required this.provider, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Obx(() => TextField(
      controller: formCtrl.apiKeyController,
      focusNode: formCtrl.apiKeyFocus,
      obscureText: !formCtrl.isApiKeyVisible.value,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: formCtrl.getApiKeyHint(provider.type),
        prefixIcon: const Icon(Icons.vpn_key_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            formCtrl.isApiKeyVisible.value
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
          ),
          onPressed: () => formCtrl.isApiKeyVisible.toggle(),
        ),
        errorText: formCtrl.apiKeyError.value,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: theme.cardColor,
      ),
    ));
  }
}

// ─── Model Field ───────────────────────────────────────

class _ModelField extends StatelessWidget {
  final AssistantSettingsFormController formCtrl;
  final SettingsController settingsCtrl;
  final AiProviderConfig provider;
  final ThemeData theme;
  final bool isAr;
  const _ModelField({
    required this.formCtrl,
    required this.settingsCtrl,
    required this.provider,
    required this.theme,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: formCtrl.modelController,
          focusNode: formCtrl.modelFocus,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: provider.defaultModel,
            prefixIcon: const Icon(Icons.model_training_outlined),
            errorText: formCtrl.modelError.value,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: theme.cardColor,
          ),
        ),
        // Suggested models chips
        if (provider.suggestedModels.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: provider.suggestedModels.map((m) => GestureDetector(
              onTap: () => formCtrl.modelController.text = m,
              child: Chip(
                label: Text(m, style: const TextStyle(fontSize: 11)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                side: BorderSide.none,
              ),
            )).toList(),
          ),
        ],
        // Gemini auto-discover button
        if (provider.type == AiProviderType.gemini) ...[
          const SizedBox(height: 8),
          Align(
            alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
            child: Obx(() => TextButton.icon(
              onPressed: settingsCtrl.isTestingAi.value
                  ? null
                  : () => settingsCtrl.discoverGeminiModels(formCtrl.apiKeyController.text),
              icon: settingsCtrl.isTestingAi.value
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text('auto_discover'.tr, style: const TextStyle(fontSize: 12)),
            )),
          ),
        ],
      ],
    ));
  }
}

// ─── Custom URL Section ────────────────────────────────

class _CustomUrlSection extends StatelessWidget {
  final AssistantSettingsFormController formCtrl;
  final ThemeData theme;
  const _CustomUrlSection({required this.formCtrl, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.link_outlined, color: AppTheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'use_custom_url'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Switch.adaptive(
                value: formCtrl.useCustomUrl.value,
                onChanged: (val) => formCtrl.useCustomUrl.value = val,
                activeThumbColor: AppTheme.primary,
                activeTrackColor: AppTheme.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
        // Animated URL field
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextField(
              controller: formCtrl.urlController,
              focusNode: formCtrl.urlFocus,
              style: theme.textTheme.bodyMedium,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://...',
                prefixIcon: const Icon(Icons.http_outlined),
                errorText: formCtrl.urlError.value,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
          ),
          crossFadeState: formCtrl.useCustomUrl.value
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    ));
  }
}

// ─── Tools Toggle ──────────────────────────────────────

class _ToolsToggle extends StatelessWidget {
  final AssistantSettingsFormController formCtrl;
  final ThemeData theme;
  const _ToolsToggle({required this.formCtrl, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.build_outlined, size: 18, color: Colors.purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'tools_enabled'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'tools_desc'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: formCtrl.toolsEnabled.value,
            onChanged: (val) => formCtrl.toolsEnabled.value = val,
            activeThumbColor: Colors.purple,
            activeTrackColor: Colors.purple.withValues(alpha: 0.5),
          ),
        ],
      ),
    ));
  }
}

// ─── Action Buttons ────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final AssistantSettingsFormController formCtrl;
  final SettingsController settingsCtrl;
  const _ActionButtons({required this.formCtrl, required this.settingsCtrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isBusy = settingsCtrl.isTestingAi.value || settingsCtrl.isSavingAi.value;

      return Column(
        children: [
          // Test Connection
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: isBusy ? Colors.grey : AppTheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: isBusy ? null : () {
                FocusManager.instance.primaryFocus?.unfocus();
                final data = formCtrl.collectFormData();
                settingsCtrl.testAiConnection(
                  apiKey: data['apiKey'],
                  model: data['model'],
                  customUrl: data['customUrl'],
                  useCustomUrl: data['useCustomUrl'],
                );
              },
              icon: settingsCtrl.isTestingAi.value
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.bolt_rounded),
              label: Text(
                settingsCtrl.isTestingAi.value ? 'testing'.tr : 'test_connection'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Save Settings
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppTheme.primary.withValues(alpha: 0.3),
              ),
              onPressed: isBusy ? null : () async {
                FocusManager.instance.primaryFocus?.unfocus();

                // 🛡️ Validate before saving
                if (!formCtrl.validateForm()) return;

                final data = formCtrl.collectFormData();
                await settingsCtrl.saveAiSettings(
                  apiKey: data['apiKey'],
                  model: data['model'],
                  customUrl: data['customUrl'],
                  useCustomUrl: data['useCustomUrl'],
                  toolsEnabled: data['toolsEnabled'],
                );
              },
              child: settingsCtrl.isSavingAi.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'save_settings'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
        ],
      );
    });
  }
}
