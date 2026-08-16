import 'package:expert_ai/services/database/firebase_database_provider.dart';
import 'package:expert_ai/services/database/database_history_item.dart';
import 'package:expert_ai/services/database/database_provider.dart';

class DatabaseService implements DatabaseProvider {
  final DatabaseProvider provider;
  DatabaseService(this.provider);

  factory DatabaseService.instance() => DatabaseService(FirebaseDatabaseProvider());

  @override
  Future<List<DatabaseHistoryItem>> fetchHistory(String userId) =>
      provider.fetchHistory(userId);

  @override
  Future<void> recordActivity({
    required String userId,
    required String agentName,
    required String query,
    required double amount,
    bool isDeduction = true,
  }) =>
      provider.recordActivity(
        userId: userId,
        agentName: agentName,
        query: query,
        amount: amount,
        isDeduction: isDeduction,
      );

  @override
  Future<void> clearHistory(String userId) => provider.clearHistory(userId);
}
