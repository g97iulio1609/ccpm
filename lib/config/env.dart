import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'OPENAI_API_KEY')
  static const String openaiApiKey = _Env.OPENAI_API_KEY;

  @EnviedField(varName: 'GEMINI_API_KEY')
  static const String geminiApiKey = _Env.GEMINI_API_KEY;

  @EnviedField(varName: 'CLAUDE_API_KEY')
  static const String claudeApiKey = _Env.CLAUDE_API_KEY;

  @EnviedField(varName: 'AZURE_OPENAI_API_KEY')
  static const String azureOpenaiApiKey = _Env.AZURE_OPENAI_API_KEY;

  @EnviedField(varName: 'AZURE_OPENAI_ENDPOINT')
  static const String azureOpenaiEndpoint = _Env.AZURE_OPENAI_ENDPOINT;
}
