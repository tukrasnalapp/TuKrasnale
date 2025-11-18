import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/krasnal.dart';

class DatabaseService {
  static const String _krasnaleKey = 'krasnale_list';

  Future<List<Krasnal>> getKrasnale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final krasnaleJson = prefs.getStringList(_krasnaleKey) ?? [];
      
      return krasnaleJson
          .map((jsonString) => Krasnal.fromMap(json.decode(jsonString)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addKrasnal(Krasnal krasnal) async {
    try {
      final krasnale = await getKrasnale();
      krasnale.add(krasnal);
      await _saveKrasnale(krasnale);
    } catch (e) {
      throw Exception('Failed to add krasnal: $e');
    }
  }

  Future<void> updateKrasnal(Krasnal krasnal) async {
    try {
      final krasnale = await getKrasnale();
      final index = krasnale.indexWhere((k) => k.id == krasnal.id);
      
      if (index != -1) {
        krasnale[index] = krasnal;
        await _saveKrasnale(krasnale);
      } else {
        throw Exception('Krasnal not found');
      }
    } catch (e) {
      throw Exception('Failed to update krasnal: $e');
    }
  }

  Future<void> deleteKrasnal(String id) async {
    try {
      final krasnale = await getKrasnale();
      krasnale.removeWhere((k) => k.id == id);
      await _saveKrasnale(krasnale);
    } catch (e) {
      throw Exception('Failed to delete krasnal: $e');
    }
  }

  Future<void> _saveKrasnale(List<Krasnal> krasnale) async {
    final prefs = await SharedPreferences.getInstance();
    final krasnaleJson = krasnale
        .map((krasnal) => json.encode(krasnal.toMap()))
        .toList();
    
    await prefs.setStringList(_krasnaleKey, krasnaleJson);
  }
}