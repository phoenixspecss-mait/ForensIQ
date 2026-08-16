import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:forensiq/services/database/app_database_provider.dart';
import 'package:forensiq/services/database/database_history_item.dart';
import 'package:forensiq/services/database/database_provider.dart';

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

  // 1. Record Full Media Scan Result to Firebase RTDB
  Future<void> recordScanResult({
    required String userId,
    required Map<String, dynamic> scanData,
  }) async {
    try {
      final scanId = scanData['id'] ?? "scan_${DateTime.now().millisecondsSinceEpoch}";
      final recordMap = {
        ...scanData,
        "timestamp": ServerValue.timestamp,
        "date": DateTime.now().toIso8601String(),
      };
      await _db.ref("scans/$userId/$scanId").set(recordMap);
      debugPrint("✅ Recorded scan $scanId to Firebase RTDB for user $userId");
    } catch (e) {
      debugPrint("Firebase recordScanResult error: $e");
    }
  }

  // 2. Fetch User Scans from Firebase RTDB
  Future<List<Map<String, dynamic>>> fetchUserScans(String userId) async {
    try {
      final snapshot = await _db.ref("scans/$userId").get().timeout(const Duration(seconds: 4));
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> map = snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> list = [];
        map.forEach((k, v) {
          if (v is Map) {
            list.add(Map<String, dynamic>.from(v));
          }
        });
        list.sort((a, b) => (b['id'] ?? '').toString().compareTo((a['id'] ?? '').toString()));
        return list;
      }
    } catch (e) {
      debugPrint("Firebase fetchUserScans error: $e");
    }
    return [];
  }

  // 3. User Settings Sync
  Future<void> saveUserSettings(String userId, Map<String, dynamic> settings) async {
    try {
      await _db.ref("users/$userId/settings").update(settings);
    } catch (e) {
      debugPrint("Firebase saveUserSettings error: $e");
    }
  }

  Future<Map<String, dynamic>?> fetchUserSettings(String userId) async {
    try {
      final snapshot = await _db.ref("users/$userId/settings").get().timeout(const Duration(seconds: 4));
      if (snapshot.exists && snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      debugPrint("Firebase fetchUserSettings error: $e");
    }
    return null;
  }

  // 4. API Key Sync
  Future<void> saveUserApiKey(String userId, String apiKey) async {
    try {
      await _db.ref("users/$userId/api_key").set({
        "key": apiKey,
        "updated_at": ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint("Firebase saveUserApiKey error: $e");
    }
  }

  Future<String?> fetchUserApiKey(String userId) async {
    try {
      final snapshot = await _db.ref("users/$userId/api_key/key").get().timeout(const Duration(seconds: 4));
      if (snapshot.exists && snapshot.value != null) {
        return snapshot.value.toString();
      }
    } catch (e) {
      debugPrint("Firebase fetchUserApiKey error: $e");
    }
    return null;
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

    await _localProvider.recordActivity(
      userId: userId,
      agentName: agentName,
      query: query,
      amount: amount,
      isDeduction: isDeduction,
    );

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
