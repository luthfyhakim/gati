import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gati/app/data/models/sport_gear_model.dart';

import 'package:gati/app/data/models/category_model.dart';

class SportGearService extends GetxService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<SportGear>> fetchAllGear() async {
    try {
      final response = await _supabase.from('sport_gear').select();
      return response.map((json) => SportGear.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error fetching sport gear: $e');
      return [];
    }
  }

  Future<List<GearCategory>> fetchGearCategories() async {
    try {
      final response = await _supabase
          .from('gear_categories')
          .select()
          .order('display_order', ascending: true);
      return response.map((json) => GearCategory.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<GearSubcategory>> fetchGearSubcategories(
    String categoryName,
  ) async {
    try {
      final response = await _supabase
          .from('gear_subcategories')
          .select()
          .eq('category_name', categoryName)
          .order('display_order', ascending: true);
      return response.map((json) => GearSubcategory.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error fetching subcategories: $e');
      return [];
    }
  }
}
