import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forensiq/services/database/database_history_item.dart';
import 'package:forensiq/services/database/database_provider.dart';

class AppDatabaseProvider implements DatabaseProvider {
  static const String _prefKeyHistory = "user_activity_history_v2";

  @override
  Future<List<DatabaseHistoryItem>> fetchHistory(String userId) async {
    List<DatabaseHistoryItem> items = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString("${_prefKeyHistory}_$userId");

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List decoded = jsonDecode(jsonStr);
        items = decoded
            .map((m) => DatabaseHistoryItem.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    }
    return items;
  }

  @override
  Future<void> recordActivity({
    required String userId,
    required String agentName,
    required String query,
    required double amount,
    bool isDeduction = true,
  }) async {
    try {
      final currentList = await fetchHistory(userId);
      final newItem = DatabaseHistoryItem.fromMap({
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "agent": agentName,
        "query": "\"$query\"",
        "amount": amount,
        "time": "Just now",
        "is_deduction": isDeduction,
      });

      currentList.insert(0, newItem);
      await _saveHistoryToPrefs(userId, currentList);
    } catch (e) {
      debugPrint("Error recording activity: $e");
    }
  }

  @override
  Future<void> clearHistory(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("${_prefKeyHistory}_$userId");
    } catch (e) {
      debugPrint("Error clearing history: $e");
    }
  }

  Future<void> _saveHistoryToPrefs(String userId, List<DatabaseHistoryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((i) => i.toMap()).toList();
      await prefs.setString("${_prefKeyHistory}_$userId", jsonEncode(jsonList));
    } catch (e) {
      debugPrint("Error saving history: $e");
    }
  }
}
