import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  deposit,
  withdrawal,
  matchEntry,
  matchWinning,
  refund
}

class WalletTransaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String description;
  final String? matchId;
  final DateTime timestamp;
  final String status;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    this.matchId,
    required this.timestamp,
    required this.status,
  });

  factory WalletTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletTransaction(
      id: doc.id,
      amount: (data['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${data['type']}',
        orElse: () => TransactionType.deposit,
      ),
      description: data['description'] ?? '',
      matchId: data['matchId'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] ?? 'completed',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'type': type.toString().split('.').last,
      'description': description,
      'matchId': matchId,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }
}

class Wallet {
  final String userId;
  final double balance;
  final List<WalletTransaction> transactions;
  final DateTime lastUpdated;

  Wallet({
    required this.userId,
    required this.balance,
    required this.transactions,
    required this.lastUpdated,
  });

  factory Wallet.fromFirestore(DocumentSnapshot doc, List<WalletTransaction> transactions) {
    final data = doc.data() as Map<String, dynamic>;
    return Wallet(
      userId: doc.id,
      balance: (data['balance'] as num).toDouble(),
      transactions: transactions,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'balance': balance,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  Wallet copyWith({
    String? userId,
    double? balance,
    List<WalletTransaction>? transactions,
    DateTime? lastUpdated,
  }) {
    return Wallet(
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
