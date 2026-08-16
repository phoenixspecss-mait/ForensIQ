import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:expert_ai/services/database/app_database_provider.dart';
import 'package:expert_ai/services/database/database_history_item.dart';
import 'package:expert_ai/services/database/database_provider.dart';

class FirebaseDatabaseProvider implements DatabaseProvider {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final AppDatabaseProvider _localProvider = AppDatabaseProvider();

  @override
  Future<List<DatabaseHistoryItem>> fetchHistory(String userId) async {
    try {
      final snapshot = await _db.ref("scans/$userId").get().timeout(const Duration(seconds: 4));
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> map = snapshot.value as Map<dynamic, dynamic>;
        final List<DatabaseHistoryItem> items = [];
        map.forEach((key, value) {
          if (value is Map) {
            items.add(DatabaseHistoryItem.fromMap(Map<String, dynamic>.from(value)));
          }
        });
        items.sort((a, b) => b.id.compareTo(a.id));
        return items;
      }
    } catch (e) {
      debugPrint("Firebase fetchHistory notice: $e; falling back to local storage");
    }
    return await _localProvider.fetchHistory(userId);
  }

  @override
  Future<void> recordActivity({
    required String userId,
    required String agentName,
    required String query,
    required double amount,
    bool isDeduction = true,
  }) async {
    final newItemMap = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "agent": agentName,
      "query": "\"$query\"",
      "amount": amount,
      "time": "Just now",
      "is_deduction": isDeduction,
      "timestamp": ServerValue.timestamp,
    };

    // Record locally for fast UI response & offline support
    await _localProvider.recordActivity(
      userId: userId,
      agentName: agentName,
      query: query,
      amount: amount,
      isDeduction: isDeduction,
    );

    // Sync to Firebase Realtime Database
    try {
      final scanId = newItemMap["id"] as String;
      await _db.ref("scans/$userId/$scanId").set(newItemMap);
    } catch (e) {
      debugPrint("Firebase recordActivity notice: $e");
    }
  }

  @override
  Future<void> clearHistory(String userId) async {
    await _localProvider.clearHistory(userId);
    try {
      await _db.ref("scans/$userId").remove();
    } catch (e) {
      debugPrint("Firebase clearHistory notice: $e");
    }
  }
}
