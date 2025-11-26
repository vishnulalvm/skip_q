import 'package:cloud_firestore/cloud_firestore.dart';

class QueueModel {
  final String id;
  final String name;
  final DateTime createdAt;
  final int currentToken;
  final int totalServed;
  final int averageServeTime; // in seconds
  final String status;
  final int? maxTokens;
  final int lastIssuedToken;
  final String adminPin;
  final int? totalBuns;
  final int? remainingBuns;

  QueueModel({
    required this.id,
    required this.name,
    required this.createdAt,
    this.currentToken = 0,
    this.totalServed = 0,
    this.averageServeTime = 120,
    this.status = 'active',
    this.maxTokens,
    this.lastIssuedToken = 0,
    required this.adminPin,
    this.totalBuns,
    this.remainingBuns,
  });

  factory QueueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QueueModel(
      id: doc.id,
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currentToken: data['currentToken'] ?? 0,
      totalServed: data['totalServed'] ?? 0,
      averageServeTime: data['averageServeTime'] ?? 120,
      status: data['status'] ?? 'active',
      maxTokens: data['maxTokens'],
      lastIssuedToken: data['lastIssuedToken'] ?? 0,
      adminPin: data['adminPin'] ?? '0000',
      totalBuns: data['totalBuns'],
      remainingBuns: data['remainingBuns'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'currentToken': currentToken,
      'totalServed': totalServed,
      'averageServeTime': averageServeTime,
      'status': status,
      if (maxTokens != null) 'maxTokens': maxTokens,
      'lastIssuedToken': lastIssuedToken,
      'adminPin': adminPin,
      if (totalBuns != null) 'totalBuns': totalBuns,
      if (remainingBuns != null) 'remainingBuns': remainingBuns,
    };
  }
}

class QueueMember {
  final String id;
  final String name;
  final int quantity;
  final int tokenNumber;
  final String status; // waiting, served, skipped
  final DateTime joinedAt;
  final DateTime? servedAt;
  final DateTime? skippedAt;

  QueueMember({
    required this.id,
    required this.name,
    required this.quantity,
    required this.tokenNumber,
    this.status = 'waiting',
    required this.joinedAt,
    this.servedAt,
    this.skippedAt,
  });

  factory QueueMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QueueMember(
      id: doc.id,
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      tokenNumber: data['tokenNumber'] ?? 0,
      status: data['status'] ?? 'waiting',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      servedAt: (data['servedAt'] as Timestamp?)?.toDate(),
      skippedAt: (data['skippedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'quantity': quantity,
      'tokenNumber': tokenNumber,
      'status': status,
      'joinedAt': Timestamp.fromDate(joinedAt),
      if (servedAt != null) 'servedAt': Timestamp.fromDate(servedAt!),
      if (skippedAt != null) 'skippedAt': Timestamp.fromDate(skippedAt!),
    };
  }

  bool get isWaiting => status == 'waiting';
  bool get isServed => status == 'served';
  bool get isSkipped => status == 'skipped';
}
