import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'archdiocese_parish_sample_data.dart';

class ArchdioceseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ArchdioceseModel>> getArchdioceses({String? country}) async {
    try {
      var query = _supabase.from('archdioceses').select();

      if (country != null && country.isNotEmpty) {
        query = query.eq('country', country);
      }

      final response = await query.eq('is_active', true).order('name');
      var archdioceses = (response as List)
          .map((json) => ArchdioceseModel.fromJson(json))
          .toList();

      // If no data from database, use sample data
      if (archdioceses.isEmpty) {
        archdioceses = ArchdioceseParishSampleData.getSampleArchdioceses();
        if (country != null && country.isNotEmpty) {
          archdioceses = archdioceses
              .where((a) => a.country == country)
              .toList();
        }
      }

      return archdioceses;
    } catch (e) {
      // Fallback to sample data if database connection fails
      var archdioceses = ArchdioceseParishSampleData.getSampleArchdioceses();
      if (country != null && country.isNotEmpty) {
        archdioceses = archdioceses.where((a) => a.country == country).toList();
      }
      return archdioceses;
    }
  }

  Future<ArchdioceseModel?> getArchdioceseById(String id) async {
    try {
      final response = await _supabase
          .from('archdioceses')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .single();

      return ArchdioceseModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<ArchdioceseModel> createArchdiocese(
    ArchdioceseModel archdiocese,
  ) async {
    try {
      final response = await _supabase
          .from('archdioceses')
          .insert(archdiocese.toJson())
          .select()
          .single();

      return ArchdioceseModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create archdiocese: $e');
    }
  }

  Future<ArchdioceseModel> updateArchdiocese(
    ArchdioceseModel archdiocese,
  ) async {
    try {
      final response = await _supabase
          .from('archdioceses')
          .update(archdiocese.toJson())
          .eq('id', archdiocese.id)
          .select()
          .single();

      return ArchdioceseModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update archdiocese: $e');
    }
  }

  Future<void> deleteArchdiocese(String id) async {
    try {
      await _supabase
          .from('archdioceses')
          .update({'is_active': false})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete archdiocese: $e');
    }
  }

  Future<List<String>> getCountries() async {
    try {
      final response = await _supabase
          .from('archdioceses')
          .select('country')
          .eq('is_active', true);

      var countries = (response as List)
          .map((item) => item['country'] as String)
          .where((country) => country.isNotEmpty)
          .toSet()
          .toList();

      // If no data from database, use sample data
      if (countries.isEmpty) {
        final sampleArchdioceses =
            ArchdioceseParishSampleData.getSampleArchdioceses();
        countries = sampleArchdioceses
            .map((a) => a.country)
            .where((country) => country.isNotEmpty)
            .toSet()
            .toList();
      }

      countries.sort();
      return countries;
    } catch (e) {
      // Fallback to sample data if database connection fails
      final sampleArchdioceses =
          ArchdioceseParishSampleData.getSampleArchdioceses();
      final countries = sampleArchdioceses
          .map((a) => a.country)
          .where((country) => country.isNotEmpty)
          .toSet()
          .toList();
      countries.sort();
      return countries;
    }
  }
}
