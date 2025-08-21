import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/macros_model.dart' as macros;
import '../models/meals_model.dart' as meals;
import '../services/meals_services.dart';
import 'food_autocomplete.dart';
import 'package:go_router/go_router.dart';
import '../../Main/app_theme.dart';
import '../../UI/components/button.dart';
import '../../UI/components/app_card.dart';
import '../../UI/components/input.dart';
import '../../UI/components/badge.dart';

class FoodSelector extends ConsumerStatefulWidget {
  final meals.Meal meal;
  final String? myFoodId;
  final VoidCallback? onSave;
  final bool isFavoriteMeal;
  final ScrollController? scrollController;

  const FoodSelector({
    required this.meal,
    this.myFoodId,
    this.onSave,
    this.isFavoriteMeal = false,
    this.scrollController,
    super.key,
  });

  @override
  FoodSelectorState createState() => FoodSelectorState();
}

class FoodSelectorState extends ConsumerState<FoodSelector> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '100');
  String _selectedFoodId = '';
  double _quantity = 100.0;
  String _unit = 'g';

  double _proteinValue = 0.0;
  double _carbsValue = 0.0;
  double _fatValue = 0.0;
  double _kcalValue = 0.0;

  Future<macros.Food?>? _foodFuture;
  macros.Food? _loadedFood;
  macros.Food? _originalFood;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.myFoodId != null) {
      _selectedFoodId = widget.myFoodId!;
      _foodFuture = _loadFoodData(widget.myFoodId!);
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<macros.Food?> _loadFoodData(String foodId) async {
    final mealsService = ref.read(mealsServiceProvider.notifier);
    final food = await mealsService.getMyFoodById(widget.meal.userId, foodId);
    if (food != null) {
      if (mounted) {
        setState(() {
          _updateLoadedFood(food);
          _updateMacronutrientValues(food);
        });
      }
      return food;
    } else {
      if (mounted) {
        setState(() {
          _resetLoadedFood();
        });
      }
      return null;
    }
  }

  void _updateLoadedFood(macros.Food food) {
    setState(() {
      _selectedFoodId = food.id!;
      _loadedFood = food;
      _originalFood = food;
      _quantity = food.quantity ?? 100.0;
      _unit = food.quantityUnit;
      _quantityController.text = _quantity.toString();
    });
  }

  void _resetLoadedFood() {
    setState(() {
      _selectedFoodId = '';
      _loadedFood = null;
    });
  }

  void _updateMacronutrientValues(macros.Food food) {
    setState(() {
      _proteinValue = food.protein * _quantity / 100;
      _carbsValue = food.carbs * _quantity / 100;
      _fatValue = food.fat * _quantity / 100;
      _kcalValue = food.kcal * _quantity / 100;
    });
  }

  Future<void> _saveFood() async {
    try {
      final mealsService = ref.read(mealsServiceProvider.notifier);
      final food = _loadedFood;
      if (food != null) {
        final adjustedFood = _createAdjustedFood(food);

        if (widget.myFoodId == null) {
          await _addFood(mealsService, adjustedFood);
        } else {
          await _updateFood(mealsService, adjustedFood);
        }

        widget.onSave?.call();
      }
    } catch (e) {
    } finally {
      if (mounted) {
        context.pop();
      }
    }
  }

  macros.Food _createAdjustedFood(macros.Food food) {
    return macros.Food(
      id: food.id,
      name: food.name,
      kcal: food.kcal * _quantity / 100,
      carbs: food.carbs * _quantity / 100,
      fat: food.fat * _quantity / 100,
      protein: food.protein * _quantity / 100,
      quantity: _quantity,
      quantityUnit: _unit,
      portion: _unit,
      sugar: food.sugar,
      fiber: food.fiber,
      saturatedFat: food.saturatedFat,
      polyunsaturatedFat: food.polyunsaturatedFat,
      monounsaturatedFat: food.monounsaturatedFat,
      transFat: food.transFat,
      cholesterol: food.cholesterol,
      sodium: food.sodium,
      potassium: food.potassium,
      vitaminA: food.vitaminA,
      vitaminC: food.vitaminC,
      calcium: food.calcium,
      iron: food.iron,
      mealId: widget.meal.id!,
    );
  }

  Future<void> _addFood(MealsService mealsService, macros.Food adjustedFood) async {
    if (widget.isFavoriteMeal) {
      await mealsService.addFoodToFavoriteMeal(
        userId: widget.meal.userId,
        mealId: widget.meal.id!,
        food: adjustedFood,
      );
    } else {
      await mealsService.addFoodToMeal(
        userId: widget.meal.userId,
        mealId: widget.meal.id!,
        food: adjustedFood,
        quantity: _quantity,
      );
    }
  }

  Future<void> _updateFood(MealsService mealsService, macros.Food adjustedFood) async {
    await mealsService.updateMyFood(
      userId: widget.meal.userId,
      myFoodId: widget.myFoodId!,
      updatedFood: adjustedFood,
    );

    if (_originalFood != null) {
      await mealsService.updateMealAndDailyStats(
        widget.meal.userId,
        widget.meal.id!,
        _originalFood!,
        isAdding: false,
      );
      await mealsService.updateMealAndDailyStats(
        widget.meal.userId,
        widget.meal.id!,
        adjustedFood,
        isAdding: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.only(
        left: AppTheme.spacing.lg,
        right: AppTheme.spacing.lg,
        top: AppTheme.spacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              boxShadow: AppTheme.elevations.small,
            ),
            child: AutoTypeField(
              controller: _searchController,
              focusNode: FocusNode(),
              onSelected: (macros.Food food) {
                setState(() {
                  _updateLoadedFood(food);
                  _quantity = 100.0;
                  _unit = 'g';
                  _quantityController.text = '100';
                  _foodFuture = Future.value(food);
                  _updateMacronutrientValues(food);
                });
              },
              onChanged: (String pattern) {
                // Pattern handling remains unchanged
              },
            ),
          ),
          if (_selectedFoodId.isNotEmpty || widget.myFoodId != null)
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildSelectedFoodDetails(context),
              ),
            ),
          SizedBox(height: AppTheme.spacing.lg),
          AppButton(
            label: 'Salva',
            icon: Icons.check_circle_outline,
            onPressed: _saveFood,
            size: AppButtonSize.full,
            variant: AppButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFoodDetails(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<macros.Food?>(
      future: _foodFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: colorScheme.primary));
        } else if (snapshot.hasData) {
          final food = snapshot.data!;
          _loadedFood = food;
          return AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      AppBadge(
                        label: '${_kcalValue.toStringAsFixed(0)} kcal',
                        variant: AppBadgeVariant.gradient,
                        status: AppBadgeStatus.primary,
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacing.md),
                  _buildQuantityInput(food),
                  SizedBox(height: AppTheme.spacing.lg),
                  Text(
                    'Macronutrienti',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppTheme.spacing.md),
                  _buildMacroItem('Proteine', _proteinValue, colorScheme.tertiary, theme),
                  SizedBox(height: AppTheme.spacing.sm),
                  _buildMacroItem('Carboidrati', _carbsValue, colorScheme.secondary, theme),
                  SizedBox(height: AppTheme.spacing.sm),
                  _buildMacroItem('Grassi', _fatValue, colorScheme.error, theme),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  SizedBox(height: AppTheme.spacing.md),
                  Text(
                    'Errore nel caricamento',
                    style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.error),
                  ),
                  SizedBox(height: AppTheme.spacing.sm),
                  Text(
                    snapshot.error.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildQuantityInput(macros.Food food) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: AppInput(
            controller: _quantityController,
            label: 'Quantità',
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _quantity = double.tryParse(value) ?? 100.0;
                _updateMacronutrientValues(food);
              });
            },
          ),
        ),
        SizedBox(width: AppTheme.spacing.md),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.md,
            vertical: AppTheme.spacing.xs,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
            border: Border.all(color: colorScheme.outline.withAlpha(51)),
          ),
          child: DropdownButton<String>(
            value: _unit,
            items: <String>['g', 'ml', 'oz'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _unit = newValue!;
                _updateMacronutrientValues(food);
              });
            },
            underline: const SizedBox.shrink(),
            icon: Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroItem(String label, double value, Color color, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color.withAlpha(51),
                borderRadius: BorderRadius.circular(AppTheme.radii.full),
                border: Border.all(color: color, width: 2),
              ),
            ),
            SizedBox(width: AppTheme.spacing.sm),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ],
        ),
        Text(
          '${value.toStringAsFixed(1)}g',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary.withAlpha(179),
          ),
        ),
      ],
    );
  }
}
