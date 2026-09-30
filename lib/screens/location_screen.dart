import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../widgets/table_card.dart';
import '../services/auth_service.dart';
import '../models/canteen_table.dart';

const List<Map<String, String>> canteenZones = [
  {'name': 'โรงอาหารตึก 1', 'floor': 'ชั้น 1'},
  {'name': 'โรงอาหารตึก 1', 'floor': 'ชั้น 2'},
  {'name': 'โรงอาหารตึก 2', 'floor': 'ชั้น 1'},
];

class LocationScreen extends StatefulWidget {
  final bool isAdmin;

  const LocationScreen({super.key, this.isAdmin = false});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String? _selectedZone;

  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  Future<void> _handleDeleteTable(
      BuildContext context, CanteenTable table) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันการลบโต๊ะ'),
          ],
        ),
        content: Text(
          table.isBooked
              ? 'โต๊ะ "${table.name}" กำลังถูกจองโดย ${table.bookedByName ?? "ผู้ใช้"}\n\nหากลบโต๊ะ ข้อมูลการจองจะหายไปด้วย ต้องการลบใช่หรือไม่?'
              : 'ต้องการลบโต๊ะ "${table.name}" ใช่หรือไม่? การกระทำนี้ไม่สามารถย้อนกลับได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบโต๊ะ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestoreService.deleteTable(table.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบโต๊ะ "${table.name}" สำเร็จ'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _handleBook(String tableId) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final latestName = await _authService.getLatestDisplayName(user.uid);

    final success = await _firestoreService.bookTable(
      tableId: tableId,
      uid: user.uid,
      userName: latestName,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(success ? 'จองโต๊ะสำเร็จ' : 'โต๊ะนี้เพิ่งถูกจองไปแล้ว')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedZone == null) {
      return _buildZoneList();
    }
    return _buildTablesInZone(_selectedZone!);
  }

  Widget _buildZoneList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: canteenZones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final zone = canteenZones[index];
        final zoneName = '${zone['name']} ${zone['floor']}';
        return Card(
          child: ListTile(
            leading: const Icon(Icons.location_on, color: Colors.deepOrange),
            title: Text(zoneName),
            subtitle: const Text('แตะเพื่อดูโต๊ะว่างในโซนนี้'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => _selectedZone = zoneName),
          ),
        );
      },
    );
  }

  Widget _buildTablesInZone(String zoneName) {
    final myUid = _authService.currentUser?.uid;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedZone = null),
              ),
              Expanded(
                child: Text(zoneName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              if (widget.isAdmin)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'เพิ่ม 4 โต๊ะในโซนนี้ (คละ 2,4,5,6)',
                  onPressed: () async {
                    await _firestoreService.seedTablesForLocation(zoneName);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('เพิ่ม 4 โต๊ะใน $zoneName สำเร็จ')),
                    );
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: _firestoreService.tablesByLocation(zoneName),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final tables = snapshot.data ?? [];
              if (tables.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.table_restaurant_outlined,
                            size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'ยังไม่มีโต๊ะใน $zoneName',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'กดปุ่มเพื่อสร้าง 4 โต๊ะ (คละที่นั่ง 2, 4, 5, 6 ที่นั่ง)',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text(
                              'เพิ่ม 4 โต๊ะในโซนนี้ (คละ 2, 4, 5, 6)'),
                          onPressed: () async {
                            await _firestoreService
                                .seedTablesForLocation(zoneName);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('เพิ่ม 4 โต๊ะใน $zoneName สำเร็จ')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: tables.length,
                itemBuilder: (context, index) {
                  final table = tables[index];
                  return TableCard(
                    table: table,
                    isMine: table.bookedByUid == myUid,
                    isAdmin: widget.isAdmin,
                    onBook: () => _handleBook(table.id),
                    onCancel: () => _firestoreService.cancelBooking(table.id),
                    onDelete: () => _handleDeleteTable(context, table),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
