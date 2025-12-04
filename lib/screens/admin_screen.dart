import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/firebase_service.dart';
import '../models/queue_model.dart';

class AdminScreen extends StatefulWidget {
  final String queueId;

  const AdminScreen({super.key, required this.queueId});


  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  String get joinUrl {
    final uri = Uri.base;
    return '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}/join/${widget.queueId}';
  }

  Future<void> _copyUrl() async {
    await Clipboard.setData(ClipboardData(text: joinUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard!')),
      );
    }
  }

  Future<void> _printQR() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Scan to Join Queue',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: joinUrl,
                  width: 300,
                  height: 300,
                ),
                pw.SizedBox(height: 20),
                pw.Text(joinUrl, style: const pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 40),
                pw.Text(
                  'SkipQ',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'queue-qr-${widget.queueId}',
    );
  }

  Future<void> _markAsServed(String memberId) async {
    try {
      await _firebaseService.markAsServed(widget.queueId, memberId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer marked as served!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _skipMember(String memberId) async {
    try {
      await _firebaseService.skipToken(widget.queueId, memberId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Customer skipped')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showFullScreenQR() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Scan to Join',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  QrImageView(
                    data: joinUrl,
                    version: QrVersions.auto,
                    size: 300,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'SkipQ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleQueueStatus(QueueModel queue) async {
    try {
      final newStatus = queue.status == 'active' ? 'paused' : 'active';
      await _firebaseService.updateQueueStatus(widget.queueId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Queue ${newStatus == 'active' ? 'resumed' : 'paused'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showUpdateItemsDialog(int? currentItems) {
    final controller = TextEditingController(
      text: currentItems?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Update Items'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Remaining Items',
            hintText: 'Enter new quantity',
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.inventory),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = int.tryParse(controller.text);
              if (quantity == null || quantity < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid number')),
                );
                return;
              }
              Navigator.pop(context);
              try {
                await _firebaseService.updateBuns(widget.queueId, quantity);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Items updated to $quantity')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetQueue() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Reset Queue?'),
        content: const Text(
          'This will reset all counts (Current, Served, Items) to zero.\n\nMember history will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firebaseService.resetQueue(widget.queueId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Queue reset successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteQueue() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Queue?'),
        content: const Text(
          'This action cannot be undone. The queue and all its data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firebaseService.deleteQueue(widget.queueId);
      if (mounted) {
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Queue deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteMember(String memberId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member?'),
        content: const Text('This will remove the member from the queue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firebaseService.deleteMember(widget.queueId, memberId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: StreamBuilder<QueueModel?>(
            stream: _firebaseService.getQueueStream(widget.queueId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Text('Manage Queue');
              return Column(
                children: [
                  Text(snapshot.data!.name),
                  if (snapshot.data!.status == 'paused')
                    const Text(
                      '(PAUSED)',
                      style: TextStyle(fontSize: 12, color: Colors.redAccent),
                    ),
                ],
              );
            },
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/');
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tv),
              tooltip: 'Open Public Display',
              onPressed: () => context.replace('/display/${widget.queueId}'),
            ),
            StreamBuilder<QueueModel?>(
              stream: _firebaseService.getQueueStream(widget.queueId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final queue = snapshot.data!;
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'toggle') _toggleQueueStatus(queue);
                    if (value == 'updateItems') _showUpdateItemsDialog(queue.remainingBuns);
                    if (value == 'reset') _resetQueue();
                    if (value == 'delete') _deleteQueue();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            queue.status == 'active'
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            queue.status == 'active'
                                ? 'Hold Queue'
                                : 'Resume Queue',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'updateItems',
                      child: Row(
                        children: [
                          Icon(Icons.inventory, color: Colors.brown[600]),
                          const SizedBox(width: 8),
                          const Text('Update Items'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reset',
                      child: Row(
                        children: [
                          Icon(Icons.restart_alt, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Reset Queue',
                            style: TextStyle(color: Colors.orange[700]),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Delete Queue',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Waiting', icon: Icon(Icons.hourglass_empty)),
              Tab(text: 'Served / Skipped', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: StreamBuilder<List<QueueMember>>(
          stream: _firebaseService.getQueueMembers(widget.queueId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final members = snapshot.data ?? [];
            final waitingMembers = members
                .where((m) => !m.isServed && !m.isSkipped)
                .toList();
            final servedMembers = members
                .where((m) => m.isServed || m.isSkipped)
                .toList();

            // Sort served members by servedAt/skippedAt descending (newest first)
            servedMembers.sort((a, b) {
              final aTime = a.servedAt ?? a.skippedAt ?? a.joinedAt;
              final bTime = b.servedAt ?? b.skippedAt ?? b.joinedAt;
              return bTime.compareTo(aTime);
            });

            return TabBarView(
              children: [
                _buildWaitingList(waitingMembers),
                _buildServedList(servedMembers),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWaitingList(List<QueueMember> members) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.isEmpty ? 2 : members.length + 1, // header + empty state OR header + members
      itemBuilder: (context, index) {
        if (index == 0) {
          return StreamBuilder<QueueModel?>(
            stream: _firebaseService.getQueueStream(widget.queueId),
            builder: (context, snapshot) {
              final queue = snapshot.data;
              int? remaining;
              if (queue?.maxTokens != null) {
                remaining = queue!.maxTokens! - queue.lastIssuedToken;
                if (remaining < 0) remaining = 0;
              }

              return Column(
                children: [
                  // Combined Stats & Share Card
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Stats Section - Static
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMiniStat('Waiting', '${members.length}'),
                              _buildMiniStat(
                                'Served',
                                '${queue?.totalServed ?? 0}',
                              ),
                              _buildMiniStat(
                                'Current',
                                '${queue?.currentToken ?? 0}',
                              ),
                              if (queue?.remainingBuns != null)
                                _buildMiniStat('Items', '${queue!.remainingBuns}'),
                              if (remaining != null)
                                _buildMiniStat('Left', '$remaining'),
                            ],
                          ),
                        ),
                        const Divider(height: 1, thickness: 1),
                        // Share Section - Expandable
                        ExpansionTile(
                          leading: Icon(Icons.share_outlined, color: Colors.grey[700]),
                          title: const Text(
                            'Share Queue',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showFullScreenQR(),
                                      icon: const Icon(Icons.qr_code, size: 18),
                                      label: const Text('QR'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _printQR(),
                                      icon: const Icon(Icons.print, size: 18),
                                      label: const Text('Print'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _copyUrl(),
                                      icon: const Icon(Icons.copy, size: 18),
                                      label: const Text('Copy'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (members.isNotEmpty)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Waiting List',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        }

        // Show empty state if no members
        if (members.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'All caught up!',
                    style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        }

        final member = members[index - 1];
        final isNext = index == 1; // First person in list

        return _buildWaitingMemberCard(member, isNext);
      },
    );
  }

  Widget _buildServedList(List<QueueMember> members) {
    if (members.isEmpty) {
      return Center(
        child: Text(
          'No history yet',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        return _buildServedMemberCard(members[index]);
      },
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildWaitingMemberCard(QueueMember member, bool isNext) {
    return Card(
      elevation: isNext ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isNext
            ? const BorderSide(color: Color(0xFF6366F1), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isNext ? const Color(0xFFEEF2FF) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#${member.tokenNumber}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isNext
                          ? const Color(0xFF6366F1)
                          : Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Quantity: ${member.quantity}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () => _deleteMember(member.id),
                ),
              ],
            ),
            if (isNext) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsServed(member.id),
                      icon: const Icon(Icons.check),
                      label: const Text('SERVE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _skipMember(member.id),
                      icon: const Icon(Icons.skip_next),
                      label: const Text('SKIP'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServedMemberCard(QueueMember member) {
    final isSkipped = member.isSkipped;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey[50],
      child: ListTile(
        leading: Text(
          '#${member.tokenNumber}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
          ),
        ),
        title: Text(
          member.name,
          style: TextStyle(
            decoration: isSkipped ? TextDecoration.lineThrough : null,
            color: Colors.grey[700],
          ),
        ),
        subtitle: Text('Quantity: ${member.quantity}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSkipped ? Colors.orange[50] : Colors.green[50],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isSkipped ? 'Skipped' : 'Served',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSkipped ? Colors.orange : Colors.green,
            ),
          ),
        ),
      ),
    );
  }
}
