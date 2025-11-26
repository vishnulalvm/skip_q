import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/queue_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new queue
  Future<String> createQueue(
    String queueName,
    String adminPin, {
    int? maxTokens,
    int? totalBuns,
  }) async {
    try {
      final queueData = QueueModel(
        id: '',
        name: queueName,
        createdAt: DateTime.now(),
        maxTokens: maxTokens,
        adminPin: adminPin,
        totalBuns: totalBuns,
        remainingBuns: totalBuns,
      );

      final docRef = await _firestore
          .collection('queues')
          .add(queueData.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create queue: $e');
    }
  }

  // ... (other methods)

  // Get all active queues
  Stream<List<QueueModel>> getActiveQueues() {
    return _firestore
        .collection('queues')
        .where('status', isEqualTo: 'active')
        // Temporarily removed orderBy to avoid index requirement
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final queues = snapshot.docs
              .map((doc) => QueueModel.fromFirestore(doc))
              .toList();
          // Sort in memory instead
          queues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return queues;
        });
  }

  // Get single queue
  Stream<QueueModel?> getQueue(String queueId) {
    return _firestore
        .collection('queues')
        .doc(queueId)
        .snapshots()
        .map((doc) => doc.exists ? QueueModel.fromFirestore(doc) : null);
  }

  // Join queue
  Future<Map<String, dynamic>> joinQueue(
    String queueId,
    String customerName,
    int quantity,
  ) async {
    try {
      // Check for max tokens limit
      final queueDoc = await _firestore.collection('queues').doc(queueId).get();
      if (!queueDoc.exists) throw Exception('Queue not found');

      final queue = QueueModel.fromFirestore(queueDoc);

      if (queue.status != 'active') {
        throw Exception('Queue is currently paused or closed.');
      }

      // Get the last token number
      final membersSnapshot = await _firestore
          .collection('queues')
          .doc(queueId)
          .collection('members')
          .orderBy('tokenNumber', descending: true)
          .limit(1)
          .get();

      int nextToken = 1;
      if (membersSnapshot.docs.isNotEmpty) {
        nextToken = membersSnapshot.docs.first.data()['tokenNumber'] + 1;
      }

      // Validate against maxTokens
      if (queue.maxTokens != null && nextToken > queue.maxTokens!) {
        throw Exception('Queue is full. Maximum limit reached.');
      }

      // Validate against remainingBuns
      if (queue.remainingBuns != null && quantity > queue.remainingBuns!) {
        throw Exception('Not enough buns available. Only ${queue.remainingBuns} remaining.');
      }

      // Add member
      final memberData = QueueMember(
        id: '',
        name: customerName,
        quantity: quantity,
        tokenNumber: nextToken,
        joinedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('queues')
          .doc(queueId)
          .collection('members')
          .add(memberData.toFirestore());

      // Update lastIssuedToken and remainingBuns in queue document
      final updateData = <String, dynamic>{
        'lastIssuedToken': nextToken,
      };
      if (queue.remainingBuns != null) {
        updateData['remainingBuns'] = queue.remainingBuns! - quantity;
      }
      await _firestore.collection('queues').doc(queueId).update(updateData);

      return {'tokenNumber': nextToken, 'memberId': docRef.id};
    } catch (e) {
      // Propagate the specific error message
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Get queue members
  Stream<List<QueueMember>> getQueueMembers(String queueId) {
    return _firestore
        .collection('queues')
        .doc(queueId)
        .collection('members')
        .orderBy('tokenNumber', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => QueueMember.fromFirestore(doc))
              .toList(),
        );
  }

  // Get single member
  Stream<QueueMember?> getMember(String queueId, String memberId) {
    return _firestore
        .collection('queues')
        .doc(queueId)
        .collection('members')
        .doc(memberId)
        .snapshots()
        .map((doc) => doc.exists ? QueueMember.fromFirestore(doc) : null);
  }

  // Mark as served
  Future<void> markAsServed(String queueId, String memberId) async {
    try {
      final memberDoc = await _firestore
          .collection('queues')
          .doc(queueId)
          .collection('members')
          .doc(memberId)
          .get();

      if (!memberDoc.exists) {
        throw Exception('Member not found');
      }

      final memberData = memberDoc.data()!;
      final tokenNumber = memberData['tokenNumber'] as int;
      final joinedAt = (memberData['joinedAt'] as Timestamp).toDate();
      final servedAt = DateTime.now();
      final serveTime = servedAt.difference(joinedAt).inSeconds;

      // Update member status
      await _firestore
          .collection('queues')
          .doc(queueId)
          .collection('members')
          .doc(memberId)
          .update({
            'status': 'served',
            'servedAt': Timestamp.fromDate(servedAt),
          });

      // Update queue statistics
      final queueDoc = await _firestore.collection('queues').doc(queueId).get();
      final queueData = queueDoc.data()!;
      final totalServed = (queueData['totalServed'] ?? 0) as int;
      final averageServeTime = (queueData['averageServeTime'] ?? 120) as int;

      final newAverageServeTime =
          ((averageServeTime * totalServed) + serveTime) ~/ (totalServed + 1);

      await _firestore.collection('queues').doc(queueId).update({
        'currentToken': tokenNumber,
        'totalServed': totalServed + 1,
        'averageServeTime': newAverageServeTime,
      });
    } catch (e) {
      throw Exception('Failed to mark as served: $e');
    }
  }

  // Skip token
  Future<void> skipToken(String queueId, String memberId) async {
    try {
      // Get member's quantity
      final memberDoc = await _firestore
          .collection('queues')
          .doc(queueId)
          .collection('members')
          .doc(memberId)
          .get();

      if (!memberDoc.exists) {
        throw Exception('Member not found');
      }

      final memberData = memberDoc.data()!;
      final quantity = memberData['quantity'] as int? ?? 0;

      // Update member status
      await _firestore
          .collection('queues')
          .doc(queueId)
          .collection('members')
          .doc(memberId)
          .update({
            'status': 'skipped',
            'skippedAt': Timestamp.fromDate(DateTime.now()),
          });

      // Restore quantity to remainingBuns if queue has bun tracking
      final queueDoc = await _firestore.collection('queues').doc(queueId).get();
      if (queueDoc.exists) {
        final queueData = queueDoc.data()!;
        final remainingBuns = queueData['remainingBuns'] as int?;
        if (remainingBuns != null) {
          await _firestore.collection('queues').doc(queueId).update({
            'remainingBuns': remainingBuns + quantity,
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to skip token: $e');
    }
  }

  // Verify PIN
  Future<bool> verifyPin(String queueId, String pin) async {
    try {
      final doc = await _firestore.collection('queues').doc(queueId).get();
      if (!doc.exists) return false;
      final queue = QueueModel.fromFirestore(doc);
      return queue.adminPin == pin;
    } catch (e) {
      return false;
    }
  }

  // Delete Queue
  Future<void> deleteQueue(String queueId) async {
    try {
      await _firestore.collection('queues').doc(queueId).delete();
    } catch (e) {
      throw Exception('Failed to delete queue: $e');
    }
  }

  // Update Queue Status (Hold/Resume)
  Future<void> updateQueueStatus(String queueId, String status) async {
    try {
      await _firestore.collection('queues').doc(queueId).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to update queue status: $e');
    }
  }

  // Delete Member
  Future<void> deleteMember(String queueId, String memberId) async {
    try {
      await _firestore
          .collection('queues')
          .doc(queueId)
          .collection('members')
          .doc(memberId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete member: $e');
    }
  }

  Stream<QueueModel?> getQueueStream(String queueId) {
    return _firestore.collection('queues').doc(queueId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return QueueModel.fromFirestore(doc);
    });
  }

  // Update remaining buns in queue
  Future<void> updateBuns(String queueId, int quantity) async {
    try {
      await _firestore.collection('queues').doc(queueId).update({
        'remainingBuns': quantity,
      });
    } catch (e) {
      throw Exception('Failed to update buns: $e');
    }
  }

  // Reset queue counts (keeps member history)
  Future<void> resetQueue(String queueId) async {
    try {
      final queueDoc = await _firestore.collection('queues').doc(queueId).get();
      if (!queueDoc.exists) throw Exception('Queue not found');

      final queueData = queueDoc.data()!;
      final totalBuns = queueData['totalBuns'] as int?;

      final updateData = <String, dynamic>{
        'currentToken': 0,
        'totalServed': 0,
        'lastIssuedToken': 0,
      };

      // Reset remaining buns to total if tracking buns
      if (totalBuns != null) {
        updateData['remainingBuns'] = totalBuns;
      }

      await _firestore.collection('queues').doc(queueId).update(updateData);
    } catch (e) {
      throw Exception('Failed to reset queue: $e');
    }
  }
}
