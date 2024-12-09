import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'ai_service.dart';

class TrainingAIService {
  final AIService aiService;

  TrainingAIService(this.aiService);

  Future<String> processTrainingQuery(String query, {
    required Map<String, dynamic> userProfile,
    required List<Map<String, dynamic>> exercises,
    required Map<String, dynamic> trainingProgram,
  }) async {
    final context = {
      'userProfile': userProfile,
      'exercises': exercises,
      'trainingProgram': trainingProgram,
    };

    return aiService.processNaturalLanguageQuery(query, context: context);
  }

  Future<String> processNaturalLanguageQuery(String query, {Map<String, dynamic>? context}) async {
    // Delegate to the underlying AI service with an optional context
    return aiService.processNaturalLanguageQuery(query, context: context);
  }

  Future<Map<String, dynamic>> analyzeExercise(String exerciseName, Map<String, dynamic> exerciseData) async {
    final query = '''
      Analyze this exercise: $exerciseName
      Exercise data: ${exerciseData.toString()}
      Provide insights about proper form, common mistakes, and progression recommendations.
    ''';

    final response = await processNaturalLanguageQuery(query);
    return {
      'exercise': exerciseName,
      'analysis': response,
    };
  }

  Future<String> suggestWorkoutModifications(String currentProgram, Map<String, dynamic> userGoals) async {
    final query = '''
      Current program: $currentProgram
      User goals: ${userGoals.toString()}
      Suggest modifications to optimize this workout program for the user's goals.
    ''';

    return processNaturalLanguageQuery(query);
  }
}

final trainingAIServiceProvider = Provider<TrainingAIService>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  return TrainingAIService(aiService);
});
