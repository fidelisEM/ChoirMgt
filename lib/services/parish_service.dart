import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'archdiocese_parish_sample_data.dart';

class ParishService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ParishModel>> getParishes({String? archdioceseId}) async {
    try {
      var query = _supabase.from('parishes').select();

      if (archdioceseId != null && archdioceseId.isNotEmpty) {
        query = query.eq('archdiocese_id', archdioceseId);
      }

      final response = await query.eq('is_active', true).order('name');
      var parishes = (response as List)
          .map((json) => ParishModel.fromJson(json))
          .toList();

      // If no data from database, use sample data
      if (parishes.isEmpty) {
        parishes = ArchdioceseParishSampleData.getSampleParishes();
        if (archdioceseId != null && archdioceseId.isNotEmpty) {
          parishes = parishes
              .where((p) => p.archdioceseId == archdioceseId)
              .toList();
        }
      }

      return parishes;
    } catch (e) {
      // Fallback to sample data if database connection fails
      var parishes = ArchdioceseParishSampleData.getSampleParishes();
      if (archdioceseId != null && archdioceseId.isNotEmpty) {
        parishes = parishes
            .where((p) => p.archdioceseId == archdioceseId)
            .toList();
      }
      return parishes;
    }
  }

  Future<ParishModel?> getParishById(String id) async {
    try {
      final response = await _supabase
          .from('parishes')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .single();

      return ParishModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<List<ParishModel>> getParishesByArchdiocese(
    String archdioceseId,
  ) async {
    try {
      final response = await _supabase
          .from('parishes')
          .select()
          .eq('archdiocese_id', archdioceseId)
          .eq('is_active', true)
          .order('name');

      var parishes = (response as List)
          .map((json) => ParishModel.fromJson(json))
          .toList();

      // If no data from database, use sample data
      if (parishes.isEmpty) {
        parishes = ArchdioceseParishSampleData.getSampleParishes()
            .where((p) => p.archdioceseId == archdioceseId)
            .toList();
      }

      return parishes;
    } catch (e) {
      // Fallback to sample data if database connection fails
      return ArchdioceseParishSampleData.getSampleParishes()
          .where((p) => p.archdioceseId == archdioceseId)
          .toList();
    }
  }

  Future<ParishModel> createParish(ParishModel parish) async {
    try {
      final response = await _supabase
          .from('parishes')
          .insert(parish.toJson())
          .select()
          .single();

      return ParishModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create parish: $e');
    }
  }

  Future<ParishModel> updateParish(ParishModel parish) async {
    try {
      final response = await _supabase
          .from('parishes')
          .update(parish.toJson())
          .eq('id', parish.id)
          .select()
          .single();

      return ParishModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update parish: $e');
    }
  }

  Future<void> deleteParish(String id) async {
    try {
      await _supabase
          .from('parishes')
          .update({'is_active': false})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete parish: $e');
    }
  }
}
