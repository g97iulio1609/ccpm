import 'package:hooks_riverpod/hooks_riverpod.dart';

final recordsFilterProvider = StateProvider<String>((ref) => '');
final recordsSortProvider = StateProvider<String>((ref) => 'date_desc');


