enum AiProviderType {
  openai,
  gemini,
  anthropic,
  openrouter,
  lmStudio,
  ollama,
}

class AiProviderConfig {
  final AiProviderType type;
  final String displayName;
  final bool requiresApiKey;
  final bool requiresModel;
  final String defaultBaseUrl;
  final String defaultModel;
  final String logoIcon; // can use material icons or a string identifier
  final List<String> suggestedModels;
  
  const AiProviderConfig({
    required this.type,
    required this.displayName,
    required this.requiresApiKey,
    required this.requiresModel,
    this.defaultBaseUrl = '',
    this.defaultModel = '',
    this.logoIcon = 'cloud',
    this.suggestedModels = const [],
  });

  static const List<AiProviderConfig> providers = [
    AiProviderConfig(
      type: AiProviderType.openai,
      displayName: 'OpenAI',
      requiresApiKey: true,
      requiresModel: true,
      defaultBaseUrl: 'https://api.openai.com/v1/chat/completions',
      defaultModel: 'gpt-4o',
      logoIcon: 'openai',
      suggestedModels: [
        'gpt-5',
        'gpt-4o', 
        'gpt-4o-mini', 
        'gpt-4-turbo',
      ],
    ),
    AiProviderConfig(
      type: AiProviderType.gemini,
      displayName: 'Gemini',
      requiresApiKey: true,
      requiresModel: true,
      defaultBaseUrl: 'https://generativelanguage.googleapis.com/v1beta/models/',
      defaultModel: 'gemini-1.5-pro',
      logoIcon: 'gemini',
      suggestedModels: [
        'gemini-2.0-pro',
        'gemini-2.0-flash',
        'gemini-1.5-pro',
        'gemini-1.5-flash',
      ],
    ),
    AiProviderConfig(
      type: AiProviderType.anthropic,
      displayName: 'Anthropic',
      requiresApiKey: true,
      requiresModel: true,
      defaultBaseUrl: 'https://api.anthropic.com/v1/messages',
      defaultModel: 'claude-3-opus-20240229',
      logoIcon: 'anthropic',
      suggestedModels: [
        'claude-4-opus',
        'claude-3-5-sonnet-latest',
        'claude-3-5-sonnet-20240620',
        'claude-3-haiku-20240307',
      ],
    ),
    AiProviderConfig(
      type: AiProviderType.openrouter,
      displayName: 'OpenRouter',
      requiresApiKey: true,
      requiresModel: true,
      defaultBaseUrl: 'https://openrouter.ai/api/v1/chat/completions',
      defaultModel: 'openai/gpt-4o',
      logoIcon: 'openrouter',
      suggestedModels: [
        'openai/gpt-4o', 
        'anthropic/claude-3.5-sonnet',
        'google/gemini-pro-1.5', 
        'meta-llama/llama-3.1-405b-instruct',
      ],
    ),
    AiProviderConfig(
      type: AiProviderType.lmStudio,
      displayName: 'LM Studio',
      requiresApiKey: false,
      requiresModel: false, // Model is usually set in LM studio GUI
      defaultBaseUrl: 'http://10.0.2.2:1234/v1/chat/completions', // 10.0.2.2 is Android emulator localhost
      logoIcon: 'lmstudio',
    ),
    AiProviderConfig(
      type: AiProviderType.ollama,
      displayName: 'Ollama',
      requiresApiKey: false,
      requiresModel: true,
      defaultBaseUrl: 'http://10.0.2.2:11434/api/chat',
      defaultModel: 'llama3',
      logoIcon: 'ollama',
      suggestedModels: ['llama3', 'mistral', 'phi3', 'gemma'],
    ),
  ];

  static AiProviderConfig fromString(String id) {
    return providers.firstWhere(
      (p) => p.type.name == id, 
      orElse: () => providers.firstWhere((p) => p.type == AiProviderType.gemini)
    );
  }
}
