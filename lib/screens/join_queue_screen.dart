import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/firebase_service.dart';
import '../models/queue_model.dart';
import 'queue_status_screen.dart';

class JoinQueueScreen extends StatefulWidget {
  final String queueId;

  const JoinQueueScreen({super.key, required this.queueId});

  @override
  State<JoinQueueScreen> createState() => _JoinQueueScreenState();
}

class _JoinQueueScreenState extends State<JoinQueueScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  bool _isJoining = false;
  bool _hasJoined = false;
  int? _tokenNumber;
  String? _memberId;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _joinQueue() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      final result = await _firebaseService.joinQueue(
        widget.queueId,
        _nameController.text.trim(),
        quantity,
      );

      if (mounted) {
        setState(() {
          _hasJoined = true;
          _tokenNumber = result['tokenNumber'];
          _memberId = result['memberId'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  int _calculatePosition(List<QueueMember> members) {
    if (_tokenNumber == null) return 0;
    final waitingBefore = members
        .where((m) => m.isWaiting && m.tokenNumber < _tokenNumber!)
        .length;
    return waitingBefore + 1;
  }

  String _formatWaitTime(int seconds) {
    if (seconds < 60) return '$seconds seconds';
    final minutes = (seconds / 60).round();
    return '$minutes minute${minutes > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<QueueModel?>(
          stream: _firebaseService.getQueue(widget.queueId),
          builder: (context, snapshot) {
            return Text(snapshot.data?.name ?? 'Join Queue');
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: StreamBuilder<QueueModel?>(
        stream: _firebaseService.getQueue(widget.queueId),
        builder: (context, queueSnapshot) {
          if (queueSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!queueSnapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Queue not found'),
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

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_hasJoined) ...[
                    // Check if queue is full
                    StreamBuilder<List<QueueMember>>(
                      stream: _firebaseService.getQueueMembers(widget.queueId),
                      builder: (context, membersSnapshot) {
                        final members = membersSnapshot.data ?? [];
                        bool isFull = false;

                        if (queue.maxTokens != null) {
                          final lastToken = members.isEmpty
                              ? 0
                              : members
                                    .map((m) => m.tokenNumber)
                                    .reduce((a, b) => a > b ? a : b);
                          if (lastToken >= queue.maxTokens!) {
                            isFull = true;
                          }
                        }

                        if (isFull) {
                          return Card(
                            color: Colors.red.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.block,
                                    size: 64,
                                    color: Colors.red.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Queue is Full',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Maximum token limit reached.\nPlease try again later.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(color: Colors.red.shade700),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Join ${queue.name}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                TextField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Your Name',
                                    hintText: 'Enter your name',
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  enabled: !_isJoining,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _quantityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantity',
                                    hintText: 'How many buns?',
                                    prefixIcon: Icon(Icons.shopping_basket),
                                  ),
                                  keyboardType: TextInputType.number,
                                  enabled: !_isJoining,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _isJoining ? null : _joinQueue,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: _isJoining
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Join Queue'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    // Success & Position Display
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 64,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Successfully Joined!',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your Token Number',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '#$_tokenNumber',
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 48,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // View Queue Button - at top for visibility
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QueueStatusScreen(
                                queueId: widget.queueId,
                                userTokenNumber: _tokenNumber,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.list_alt),
                        label: const Text('View Queue'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Position & Wait Time
                    StreamBuilder<QueueMember?>(
                      stream: _memberId != null
                          ? _firebaseService.getMember(
                              widget.queueId,
                              _memberId!,
                            )
                          : null,
                      builder: (context, memberSnapshot) {
                        final member = memberSnapshot.data;

                        if (member?.isServed == true) {
                          return Card(
                            color: Colors.blue.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.celebration,
                                    size: 64,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Your order has been served!',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Thank you for waiting!',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (member?.isSkipped == true) {
                          return Card(
                            color: Colors.orange.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 64,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Your token was skipped',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Please contact the counter',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return StreamBuilder<List<QueueMember>>(
                          stream: _firebaseService.getQueueMembers(
                            widget.queueId,
                          ),
                          builder: (context, membersSnapshot) {
                            final members = membersSnapshot.data ?? [];
                            final position = _calculatePosition(members);
                            final waitTime =
                                (position - 1) * queue.averageServeTime;

                            return Column(
                              children: [
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Your Position',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$position',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineLarge
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 64,
                                              ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Estimated Wait Time',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatWaitTime(waitTime),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(color: Colors.orange),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'This page will update automatically. Please wait for your turn.',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
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
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
