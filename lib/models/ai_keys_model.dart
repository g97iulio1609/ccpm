import 'package:cloud_firestore/cloud_firestore.dart';

class AIKeysModel {
  final String? defaultOpenAIKey;
  final String? defaultGeminiKey;
  final String? defaultClaudeKey;
  final String? defaultAzureKey;
  final String? defaultAzureEndpoint;
  final String? personalOpenAIKey;
  final String? personalGeminiKey;
  final String? personalClaudeKey;
  final String? personalAzureKey;
  final String? personalAzureEndpoint;
  final String userId;

  AIKeysModel({
    this.defaultOpenAIKey,
    this.defaultGeminiKey,
    this.defaultClaudeKey,
    this.defaultAzureKey,
    this.defaultAzureEndpoint,
    this.personalOpenAIKey,
    this.personalGeminiKey,
    this.personalClaudeKey,
    this.personalAzureKey,
    this.personalAzureEndpoint,
    required this.userId,
  });

  factory AIKeysModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AIKeysModel(
      defaultOpenAIKey: data['defaultOpenAIKey'],
      defaultGeminiKey: data['defaultGeminiKey'],
      defaultClaudeKey: data['defaultClaudeKey'],
      defaultAzureKey: data['defaultAzureKey'],
      defaultAzureEndpoint: data['defaultAzureEndpoint'],
      personalOpenAIKey: data['personalOpenAIKey'],
      personalGeminiKey: data['personalGeminiKey'],
      personalClaudeKey: data['personalClaudeKey'],
      personalAzureKey: data['personalAzureKey'],
      personalAzureEndpoint: data['personalAzureEndpoint'],
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'defaultOpenAIKey': defaultOpenAIKey,
      'defaultGeminiKey': defaultGeminiKey,
      'defaultClaudeKey': defaultClaudeKey,
      'defaultAzureKey': defaultAzureKey,
      'defaultAzureEndpoint': defaultAzureEndpoint,
      'personalOpenAIKey': personalOpenAIKey,
      'personalGeminiKey': personalGeminiKey,
      'personalClaudeKey': personalClaudeKey,
      'personalAzureKey': personalAzureKey,
      'personalAzureEndpoint': personalAzureEndpoint,
      'userId': userId,
    };
  }

  AIKeysModel copyWith({
    String? defaultOpenAIKey,
    String? defaultGeminiKey,
    String? defaultClaudeKey,
    String? defaultAzureKey,
    String? defaultAzureEndpoint,
    String? personalOpenAIKey,
    String? personalGeminiKey,
    String? personalClaudeKey,
    String? personalAzureKey,
    String? personalAzureEndpoint,
    String? userId,
  }) {
    return AIKeysModel(
      defaultOpenAIKey: defaultOpenAIKey ?? this.defaultOpenAIKey,
      defaultGeminiKey: defaultGeminiKey ?? this.defaultGeminiKey,
      defaultClaudeKey: defaultClaudeKey ?? this.defaultClaudeKey,
      defaultAzureKey: defaultAzureKey ?? this.defaultAzureKey,
      defaultAzureEndpoint: defaultAzureEndpoint ?? this.defaultAzureEndpoint,
      personalOpenAIKey: personalOpenAIKey ?? this.personalOpenAIKey,
      personalGeminiKey: personalGeminiKey ?? this.personalGeminiKey,
      personalClaudeKey: personalClaudeKey ?? this.personalClaudeKey,
      personalAzureKey: personalAzureKey ?? this.personalAzureKey,
      personalAzureEndpoint: personalAzureEndpoint ?? this.personalAzureEndpoint,
      userId: userId ?? this.userId,
    );
  }

  String? getEffectiveKey(String keyType) {
    String? personalKey;
    String? defaultKey;

    switch (keyType) {
      case 'openai':
        personalKey = personalOpenAIKey;
        defaultKey = defaultOpenAIKey;
        break;
      case 'gemini':
        personalKey = personalGeminiKey;
        defaultKey = defaultGeminiKey;
        break;
      case 'claude':
        personalKey = personalClaudeKey;
        defaultKey = defaultClaudeKey;
        break;
      case 'azure':
        personalKey = personalAzureKey;
        defaultKey = defaultAzureKey;
        break;
      case 'azure_endpoint':
        personalKey = personalAzureEndpoint;
        defaultKey = defaultAzureEndpoint;
        break;
      default:
        return null;
    }

    // Se la chiave personale è vuota o null, usa quella di default
    if (personalKey == null || personalKey.isEmpty) {
      return defaultKey?.isNotEmpty == true ? defaultKey : null;
    }
    return personalKey;
  }
}
