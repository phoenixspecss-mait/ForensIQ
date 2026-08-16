import 'package:forensiq/services/database/database_history_item.dart';

abstract class DatabaseProvider {
  Future<List<DatabaseHistoryItem>> fetchHistory(String userId);
  Future<void> recordActivity({
    required String userId,
    required String agentName,
    required String query,
    required double amount,
    bool isDeduction = true,
  });
  Future<void> clearHistory(String userId);
}
