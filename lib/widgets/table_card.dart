import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/canteen_table.dart';

class TableCard extends StatelessWidget {
  final CanteenTable table;
  final bool isMine;
  final bool isAdmin;
  final VoidCallback onBook;
  final VoidCallback onCancel;
  final VoidCallback? onDelete;

  const TableCard({
    super.key,
    required this.table,
    required this.isMine,
    this.isAdmin = false,
    required this.onBook,
    required this.onCancel,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
        table.isBooked ? (isMine ? Colors.blue : Colors.red) : Colors.green;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: statusColor.withValues(alpha: 0.15),
              child: Icon(Icons.table_restaurant, color: statusColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(table.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(table.location,
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text('นั่งได้ ${table.capacity} ที่'),
                  if (table.isBooked) _buildBookedByInfo(statusColor),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(),
                if (isAdmin && onDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'ลบโต๊ะ (Admin)',
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookedByInfo(Color statusColor) {
    if (table.bookedByUid == null || table.bookedByUid!.isEmpty) {
      final name = table.bookedByName ?? '-';
      return Text(
        isMine ? 'คุณจองโต๊ะนี้อยู่ ($name)' : 'จองโดย $name',
        style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(table.bookedByUid)
          .snapshots(),
      builder: (context, snapshot) {
        String name = table.bookedByName ?? '-';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final currentName = data?['displayName'] as String?;
          if (currentName != null && currentName.trim().isNotEmpty) {
            name = currentName.trim();
          }
        }
        return Text(
          isMine ? 'คุณจองโต๊ะนี้อยู่ ($name)' : 'จองโดย $name',
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
        );
      },
    );
  }

  Widget _buildActionButton() {
    if (!table.isBooked) {
      return FilledButton(onPressed: onBook, child: const Text('จอง'));
    }
    if (isMine) {
      return OutlinedButton(onPressed: onCancel, child: const Text('ยกเลิก'));
    }
    return const Chip(label: Text('เต็ม'));
  }
}
