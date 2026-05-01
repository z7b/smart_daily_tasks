import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../../core/services/assistant/ai_provider_config.dart';
import '../controllers/assistant_settings_form_controller.dart';

class AssistantSettingsView extends GetView<SettingsController> {
  const AssistantSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Get.isDarkMode;
    final isAr = Get.locale?.languageCode == 'ar';
    
    // Initialize the form controller for persistent state management
    final formController = Get.put(AssistantSettingsFormController());


    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'extensions'.tr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProviderCard(theme, formController, isDarkMode, isAr),
              const SizedBox(height: 20),
              _buildWarningCard(theme, isDarkMode, isAr),
              const SizedBox(height: 30),
              _buildSaveButton(formController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(ThemeData theme, AssistantSettingsFormController formController, bool isDarkMode, bool isAr) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF161618) : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : theme.dividerColor.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider Dropdown
          _buildProviderDropdown(theme, isDarkMode, isAr),
          const SizedBox(height: 20),
          
          Obx(() {
            final provider = controller.activeAiProvider;
            return Column(
              children: [
                if (provider.requiresApiKey) ...[
                  _buildLabel('api_key'.tr, isAr, theme),
                  _buildTextField(
                    controller: formController.apiKeyController,
                    focusNode: formController.apiKeyFocus,
                    hintText: formController.getApiKeyHint(provider.type),
                    obscureText: true,
                    icon: Icons.vpn_key_rounded,
                    theme: theme,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 20),
                ],
                
                if (provider.requiresModel) ...[
                  _buildLabel('model_label'.tr, isAr, theme),
                  _buildTextField(
                    controller: formController.modelController,
                    focusNode: formController.modelFocus,
                    hintText: provider.defaultModel,
                    icon: Icons.model_training_rounded,
                    theme: theme,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 8),
                  
                  // ✨ Suggested Models Chips & Auto Detect
                  if (provider.suggestedModels.isNotEmpty) 
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: provider.suggestedModels.map((m) => GestureDetector(
                              onTap: () => formController.modelController.text = m,
                              child: Chip(
                                label: Text(m, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                              ),
                            )).toList(),
                          ),
                          if (provider.type == AiProviderType.gemini) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: controller.isTestingAi.value ? null : () async {
                                await controller.discoverGeminiModels(formController.apiKeyController.text);
                                formController.modelController.text = controller.aiModel.value;
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    controller.isTestingAi.value 
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                      : Icon(Icons.auto_awesome, size: 14, color: AppTheme.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      controller.isTestingAi.value ? 'discovering_models'.tr : 'auto_detect'.tr, 
                                      style: TextStyle(
                                        color: AppTheme.primary, 
                                        fontSize: 12, 
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      )
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],

                // Custom URL Checkbox (Always available as an override)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('custom_url_label'.tr, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: controller.aiUseCustomUrl.value,
                        onChanged: (val) {
                          controller.aiUseCustomUrl.value = val ?? false;
                        },
                        activeColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ],
                ),
                
                if (controller.aiUseCustomUrl.value) ...[
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: formController.urlController,
                    focusNode: formController.urlFocus,
                    hintText: 'http://...',
                    icon: Icons.link,
                    theme: theme,
                    isDarkMode: isDarkMode,
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Tools Enable Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.build_rounded, size: 20, color: theme.textTheme.titleMedium?.color?.withValues(alpha: 0.7)),
                        const SizedBox(width: 8),
                        Text('enable_tools'.tr, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
                          ),
                          child: Text('experimental'.tr, style: const TextStyle(color: Colors.purpleAccent, fontSize: 10)),
                        )
                      ],
                    ),
                    Switch(
                      value: controller.aiToolsEnabled.value,
                      onChanged: (val) {
                        controller.aiToolsEnabled.value = val;
                      },
                      activeThumbColor: AppTheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'tools_description'.tr,
                  style: TextStyle(
                    fontSize: 12, 
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6), 
                    height: 1.5
                  ),
                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProviderDropdown(ThemeData theme, bool isDarkMode, bool isAr) {
    return Column(
      crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text('ai_provider'.tr, style: TextStyle(fontSize: 12, color: AppTheme.primary)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primary, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: Obx(() => DropdownButton<String>(
              value: controller.aiProviderId.value,
              dropdownColor: isDarkMode ? const Color(0xFF1E1E1E) : theme.cardColor,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down_rounded, color: theme.iconTheme.color?.withValues(alpha: 0.7)),
              items: AiProviderConfig.providers.map((provider) {
                return DropdownMenuItem(
                  value: provider.type.name,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(provider.displayName, style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge?.color
                      )),
                      _getProviderIcon(provider.logoIcon, theme),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.changeAiProvider(value);
                }
              },
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, bool isAr, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, left: 12, bottom: 4),
      child: Align(
        alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(text, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7))),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String hintText, 
    bool obscureText = false, 
    required IconData icon,
    required ThemeData theme,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: isDarkMode ? 0.2 : 0.1)),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        style: TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodyLarge?.color
        ),
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: Icon(icon, color: theme.iconTheme.color?.withValues(alpha: 0.7), size: 20),
        ),
      ),
    );
  }

  Widget _getProviderIcon(String iconName, ThemeData theme) {
    IconData iconData;
    switch(iconName) {
      case 'openai': iconData = Icons.auto_awesome; break;
      case 'gemini': iconData = Icons.star_sharp; break;
      case 'anthropic': iconData = Icons.text_snippet_rounded; break;
      case 'openrouter': iconData = Icons.swap_horiz_rounded; break;
      case 'lmstudio': iconData = Icons.computer_rounded; break;
      case 'ollama': iconData = Icons.memory_rounded; break;
      case 'shield': iconData = Icons.shield_rounded; break;
      default: iconData = Icons.cloud;
    }
    return Icon(iconData, size: 20, color: theme.iconTheme.color);
  }

  Widget _buildWarningCard(ThemeData theme, bool isDarkMode, bool isAr) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF161618) : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : theme.dividerColor.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Switch(value: false, onChanged: (v){}, activeThumbColor: Colors.grey),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
                ),
                child: Text('experimental'.tr, style: const TextStyle(color: Colors.purpleAccent, fontSize: 10)),
              ),
              const SizedBox(width: 8),
              Text('external_notes'.tr, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'external_notes_description'.tr,
            style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7), height: 1.5),
            textAlign: isAr ? TextAlign.right : TextAlign.left,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF5A1A1A) : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  'note_warning_1'.tr, 
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.red.shade900, fontSize: 13, height: 1.5),
                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                ),
                const SizedBox(height: 8),
                Text(
                  'note_warning_2'.tr, 
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.red.shade900, fontSize: 13, height: 1.5),
                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSaveButton(AssistantSettingsFormController formController) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Obx(() => OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: controller.isTestingAi.value ? Colors.grey : AppTheme.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: controller.isTestingAi.value ? null : () {
              controller.testAiConnection(
                apiKey: formController.apiKeyController.text,
                model: formController.modelController.text,
                customUrl: formController.urlController.text,
                useCustomUrl: controller.aiUseCustomUrl.value,
              );
            },
            icon: controller.isTestingAi.value 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Icon(Icons.bolt_rounded),
            label: Text(
              controller.isTestingAi.value ? 'testing_connection'.tr : 'test_connection'.tr, 
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
          )),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: AppTheme.primary.withValues(alpha: 0.4),
            ),
            onPressed: () {
              // Ensure focus is removed before saving to trigger any final changes
              FocusManager.instance.primaryFocus?.unfocus();
              controller.saveAiSettings(
                apiKey: formController.apiKeyController.text,
                model: formController.modelController.text,
                customUrl: formController.urlController.text,
                useCustomUrl: controller.aiUseCustomUrl.value,
                toolsEnabled: controller.aiToolsEnabled.value,
              );
            },
            child: Text('save_settings'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
