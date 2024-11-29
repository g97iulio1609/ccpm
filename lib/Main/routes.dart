class Routes {
  // Auth & Home
  static const String home = '/';
  static const String auth = '/auth';

  // Programs
  static const String programsScreen = '/programs_screen';
  static const String userPrograms = '/user_programs';
  static const String trainingProgram = 'training_program';
  static const String week = 'week';
  static const String workout = 'workout';

  // Training Viewer
  static const String trainingViewer = 'training_viewer';
  static const String weekDetails = 'week_details';
  static const String workoutDetails = 'workout_details';
  static const String exerciseDetails = 'exercise_details';
  static const String timer = 'timer';

  // Gallery & Subscriptions
  static const String trainingGallery = '/training_gallery';
  static const String subscriptions = '/subscriptions';
  static const String status = '/status';

  // Measurements & Nutrition
  static const String measurements = '/measurements';
  static const String tdee = '/tdee';
  static const String macrosSelector = '/macros_selector';

  // Meals
  static const String myMeals = '/mymeals';
  static const String favoriteMealDetail = 'favorite_meal_detail';

  // Food Tracking
  static const String foodTracker = '/food_tracker';
  static const String foodSelector = 'food_selector';
  static const String dietPlan = 'diet_plan';
  static const String dietPlanEdit = 'diet_plan/edit';
  static const String viewDietPlans = 'view_diet_plans';
  static const String foodManagement = '/food_management';

  // Exercise Management
  static const String exercisesList = '/exercises_list';
  static const String maxRmDashboard = '/maxrmdashboard';
  static const String exerciseStats = 'exercise_stats/:exerciseId';

  // Users & Profile
  static const String usersDashboard = '/users_dashboard';
  static const String userProfile = '/user_profile';
  static const String associations = '/associations';
}
