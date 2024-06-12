import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'week_services.dart';

final weekServiceProvider = Provider<WeekService>((ref) => WeekService());
