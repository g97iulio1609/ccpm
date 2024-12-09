import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'OPENAI_API_KEY')
  static const String OPENAI_API_KEY = _Env.OPENAI_API_KEY;

  @EnviedField(varName: 'GEMINI_API_KEY')
  static const String GEMINI_API_KEY = _Env.GEMINI_API_KEY;

  @EnviedField(varName: 'CLAUDE_API_KEY')
  static const String CLAUDE_API_KEY = _Env.CLAUDE_API_KEY;

  @EnviedField(varName: 'AZURE_OPENAI_API_KEY')
  static const String AZURE_OPENAI_API_KEY = _Env.AZURE_OPENAI_API_KEY;

  @EnviedField(varName: 'AZURE_OPENAI_ENDPOINT')
  static const String AZURE_OPENAI_ENDPOINT = _Env.AZURE_OPENAI_ENDPOINT;
}
