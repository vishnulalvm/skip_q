import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/queue_model.dart';

class QueueStatusScreen extends StatelessWidget {
  final String queueId;
  final int? userTokenNumber;

  const QueueStatusScreen({
    super.key,
    required this.queueId,
    this.userTokenNumber,
  });

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Status'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QueueModel?>(
        stream: firebaseService.getQueueStream(queueId),
        builder: (context, queueSnapshot) {
          if (!queueSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final queue = queueSnapshot.data!;

          return StreamBuilder<List<QueueMember>>(
            stream: firebaseService.getQueueMembers(queueId),
            builder: (context, membersSnapshot) {
              final allMembers = membersSnapshot.data ?? [];
              final waitingMembers = allMembers
                  .where((m) => m.isWaiting)
                  .toList();

              return Column(
                children: [
                  // Stats Card
                  Card(
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            queue.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStat(
                                context,
                                'Current',
                                '#${queue.currentToken}',
                                Icons.confirmation_number,
                                Colors.blue,
                              ),
                              _buildStat(
                                context,
                                'Waiting',
                                '${waitingMembers.length}',
                                Icons.people,
                                Colors.orange,
                              ),
                              if (queue.remainingBuns != null)
                                _buildStat(
                                  context,
                                  'Items Left',
                                  '${queue.remainingBuns}',
                                  Icons.inventory,
                                  queue.remainingBuns == 0 ? Colors.red : Colors.brown,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // User's Position (if token provided)
                  if (userTokenNumber != null) ...[
                    _buildUserPositionCard(context, waitingMembers, queue),
                  ],

                  // Waiting List Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.list, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Waiting List',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Waiting List
                  Expanded(
                    child: waitingMembers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'No one waiting',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: waitingMembers.length,
                            itemBuilder: (context, index) {
                              final member = waitingMembers[index];
                              final isCurrentUser = member.tokenNumber == userTokenNumber;

                              return Card(
                                color: isCurrentUser
                                    ? Colors.green.shade50
                                    : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: isCurrentUser
                                      ? BorderSide(color: Colors.green.shade400, width: 2)
                                      : BorderSide.none,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isCurrentUser
                                        ? Colors.green
                                        : Colors.grey[300],
                                    child: Text(
                                      '#${member.tokenNumber}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrentUser
                                            ? Colors.white
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          member.name,
                                          style: TextStyle(
                                            fontWeight: isCurrentUser
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isCurrentUser)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'YOU',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text('Qty: ${member.quantity}'),
                                  trailing: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrentUser
                                          ? Colors.green
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUserPositionCard(
    BuildContext context,
    List<QueueMember> waitingMembers,
    QueueModel queue,
  ) {
    final userPosition = waitingMembers
        .indexWhere((m) => m.tokenNumber == userTokenNumber);

    if (userPosition == -1) {
      return const SizedBox.shrink();
    }

    final position = userPosition + 1;
    final waitTime = userPosition * queue.averageServeTime;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.green,
              child: Text(
                '$position',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Position: #$position',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Token: #$userTokenNumber',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    'Est. Wait: ${_formatWaitTime(waitTime)}',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatWaitTime(int seconds) {
    if (seconds < 60) return '$seconds sec';
    final minutes = (seconds / 60).round();
    return '$minutes min';
  }
}
