import 'package:flutter/material.dart';

class RouteMeta {
  final String path;
  final String title;
  final IconData icon;
  const RouteMeta({
    required this.path,
    required this.title,
    required this.icon,
  });
}

// Mappa principale di metadati per rotte top-level e secondarie comuni
class RouteMetadata {
  static const Map<String, RouteMeta> metaByPath = {
    '/programs_screen': RouteMeta(
      path: '/programs_screen',
      title: 'Coaching',
      icon: Icons.people,
    ),
    '/user_programs': RouteMeta(
      path: '/user_programs',
      title: 'I Miei Allenamenti',
      icon: Icons.fitness_center,
    ),
    '/exercises_list': RouteMeta(
      path: '/exercises_list',
      title: 'Esercizi',
      icon: Icons.sports,
    ),
    '/subscriptions': RouteMeta(
      path: '/subscriptions',
      title: 'Abbonamenti',
      icon: Icons.subscriptions,
    ),
    '/maxrmdashboard': RouteMeta(
      path: '/maxrmdashboard',
      title: 'Massimali',
      icon: Icons.trending_up,
    ),
    '/user_profile': RouteMeta(
      path: '/user_profile',
      title: 'Profilo Utente',
      icon: Icons.person,
    ),
    '/users_dashboard': RouteMeta(
      path: '/users_dashboard',
      title: 'Gestione Utenti',
      icon: Icons.supervised_user_circle,
    ),
    '/measurements': RouteMeta(
      path: '/measurements',
      title: 'Misurazioni',
      icon: Icons.straighten,
    ),
    '/tdee': RouteMeta(
      path: '/tdee',
      title: 'Fabbisogno Calorico',
      icon: Icons.local_fire_department,
    ),
    '/macros_selector': RouteMeta(
      path: '/macros_selector',
      title: 'Calcolatore Macronutrienti',
      icon: Icons.pie_chart,
    ),
    '/training_gallery': RouteMeta(
      path: '/training_gallery',
      title: 'Galleria Allenamenti',
      icon: Icons.collections_bookmark,
    ),
    '/food_tracker': RouteMeta(
      path: '/food_tracker',
      title: 'Tracciatore Cibo',
      icon: Icons.restaurant_menu,
    ),
    '/food_management': RouteMeta(
      path: '/food_management',
      title: 'Food Management',
      icon: Icons.fastfood,
    ),
    '/mymeals': RouteMeta(
      path: '/mymeals',
      title: 'Meals Preferiti',
      icon: Icons.favorite,
    ),
    '/mydays': RouteMeta(
      path: '/mydays',
      title: 'Giorni Preferiti',
      icon: Icons.calendar_month,
    ),
    '/settings/ai': RouteMeta(
      path: '/settings/ai',
      title: 'Impostazioni AI',
      icon: Icons.smart_toy,
    ),
    '/ai/chat': RouteMeta(
      path: '/ai/chat',
      title: 'AI Assistant',
      icon: Icons.chat,
    ),
    '/associations': RouteMeta(
      path: '/associations',
      title: 'Association',
      icon: Icons.people_outline,
    ),
  };

  static RouteMeta? resolveByCurrentPath(String currentPath) {
    // match startsWith for paths che includono parametri (es: /user_profile/<id>)
    for (final entry in metaByPath.entries) {
      if (currentPath == entry.key || currentPath.startsWith('${entry.key}/')) {
        return entry.value;
      }
    }
    return null;
  }
}
