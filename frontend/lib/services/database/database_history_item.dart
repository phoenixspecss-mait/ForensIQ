import 'package:flutter/material.dart';

class DatabaseHistoryItem {
  final String id;
  final String agentName;
  final String query;
  final double amount;
  final String timeAgo;
  final bool isDeduction;
  final IconData icon;
  final Color color;

  DatabaseHistoryItem({
    required this.id,
    required this.agentName,
    required this.query,
    required this.amount,
    required this.timeAgo,
    required this.isDeduction,
    required this.icon,
    required this.color,
  });

  factory DatabaseHistoryItem.fromMap(Map<String, dynamic> map) {
    final agent = map['agent'] ?? map['agent_id'] ?? 'Specialist Agent';
    final queryText = map['query'] ?? map['query_text'] ?? 'Agent Execution';
    final isDed = map['is_deduction'] ?? true;
    final amt = (map['amount'] as num?)?.toDouble() ?? 0.005;
    final timeStr = map['time'] ?? map['date'] ?? 'Just now';

    IconData itemIcon = Icons.auto_awesome_rounded;
    Color itemColor = const Color(0xFF00B894);

    final lowerAgent = agent.toString().toLowerCase();
    if (lowerAgent.contains('legal') || lowerAgent.contains('clause') || lowerAgent.contains('contract')) {
      itemIcon = Icons.gavel_rounded;
      itemColor = const Color(0xFF3A26B5);
    } else if (lowerAgent.contains('slang') || lowerAgent.contains('punjabi') || lowerAgent.contains('hindi') || lowerAgent.contains('linguis')) {
      itemIcon = Icons.translate_rounded;
      itemColor = const Color(0xFF00B894);
    } else if (lowerAgent.contains('symptom') || lowerAgent.contains('triage') || lowerAgent.contains('medical') || lowerAgent.contains('health')) {
      itemIcon = Icons.medical_services_rounded;
      itemColor = const Color(0xFFE17055);
    } else if (lowerAgent.contains('resume') || lowerAgent.contains('code') || lowerAgent.contains('career') || lowerAgent.contains('tech')) {
      itemIcon = Icons.code_rounded;
      itemColor = const Color(0xFF0984E3);
    } else if (lowerAgent.contains('top up') || lowerAgent.contains('wallet')) {
      itemIcon = Icons.account_balance_wallet_rounded;
      itemColor = const Color(0xFF00CEC9);
    }

    return DatabaseHistoryItem(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      agentName: agent.toString(),
      query: queryText.toString(),
      amount: amt,
      timeAgo: timeStr.toString(),
      isDeduction: isDed,
      icon: itemIcon,
      color: itemColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'agent': agentName,
      'query': query,
      'amount': amount,
      'time': timeAgo,
      'is_deduction': isDeduction,
    };
  }
}
