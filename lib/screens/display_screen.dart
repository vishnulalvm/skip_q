import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/firebase_service.dart';
import '../models/queue_model.dart';

class DisplayScreen extends StatefulWidget {
  final String queueId;

  const DisplayScreen({super.key, required this.queueId});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  final FirebaseService _firebaseService = FirebaseService();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6366F1),
      body: StreamBuilder<QueueModel?>(
        stream: _firebaseService.getQueue(widget.queueId),
        builder: (context, queueSnapshot) {
          if (queueSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (!queueSnapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Queue not found',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            );
          }

          final queue = queueSnapshot.data!;

          return StreamBuilder<List<QueueMember>>(
            stream: _firebaseService.getQueueMembers(widget.queueId),
            builder: (context, membersSnapshot) {
              final members = membersSnapshot.data ?? [];
              final waitingMembers = members.where((m) => m.isWaiting).toList();
              final currentMember = waitingMembers.isNotEmpty
                  ? waitingMembers.first
                  : null;

              return Stack(
                children: [
                  // Main Display
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          queue.name,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 48),
                          padding: const EdgeInsets.all(48),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Now Serving',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (currentMember != null) ...[
                                Text(
                                  '#${currentMember.tokenNumber}',
                                  style: const TextStyle(
                                    fontSize: 120,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6366F1),
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  currentMember.name,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ] else ...[
                                const Icon(
                                  Icons.hourglass_empty,
                                  size: 80,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Waiting for customers...',
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                        if (waitingMembers.length > 1) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.people,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${waitingMembers.length - 1} waiting in queue',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Back Button
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.go('/admin/${widget.queueId}');
                        }
                      },
                    ),
                  ),

                  // Stats in corner
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Served: ${queue.totalServed}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Waiting: ${waitingMembers.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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
}
