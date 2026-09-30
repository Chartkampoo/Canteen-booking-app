import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/table_card.dart';
import '../widgets/menu_of_the_day_card.dart';
import 'profile_screen.dart';
import 'location_screen.dart';
import '../models/canteen_table.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  int _currentIndex = 0;
  bool _isAdmin = false;

  List<Widget> get _pages => [
        _TableListView(
          firestoreService: _firestoreService,
          authService: _authService,
          isAdmin: _isAdmin,
        ),
        LocationScreen(isAdmin: _isAdmin),
        const ProfileScreen(),
      ];

  @override
  void initState() {
    super.initState();
    _loadAdminStatus();
  }

  Future<void> _loadAdminStatus() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    final profile = await _authService.fetchProfile(uid);
    if (mounted) {
      setState(() => _isAdmin = profile?.isAdmin ?? false);
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('ต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ออกจากระบบ')),
        ],
      ),
    );
    if (shouldLogout == true) {
      await _authService.logout();
    }
  }

  Future<void> _confirmSeedDefaultTables(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('สร้างโต๊ะเริ่มต้น'),
        content: const Text(
          'ระบบจะสร้างโต๊ะ 4 โต๊ะต่อสถานที่ (คละที่นั่ง 2, 4, 5, 6) รวม 12 โต๊ะ:\n\n'
          '• โรงอาหารตึก 1 ชั้น 1 (A1=2, A2=4, A3=5, A4=6)\n'
          '• โรงอาหารตึก 1 ชั้น 2 (B1=2, B2=4, B3=5, B4=6)\n'
          '• โรงอาหารตึก 2 ชั้น 1 (C1=2, C2=4, C3=5, C4=6)\n\n'
          'ต้องการดำเนินการใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('สร้างทันที'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestoreService.seedDefaultTables();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'สร้างโต๊ะเริ่มต้น 4 โต๊ะต่อสถานที่เรียบร้อยแล้ว (12 โต๊ะ)'),
          ),
        );
      }
    }
  }

  Future<void> _showAddTableDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final capacityController = TextEditingController(text: '4');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เพิ่มโต๊ะใหม่'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: 'ชื่อโต๊ะ เช่น โต๊ะ A1'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'กรุณากรอกชื่อโต๊ะ' : null,
              ),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                    labelText: 'สถานที่ เช่น โรงอาหารตึก 1 ชั้น 1'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'กรุณากรอกสถานที่' : null,
              ),
              TextFormField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'จำนวนที่นั่ง'),
                validator: (v) => (v == null || int.tryParse(v) == null)
                    ? 'กรอกเป็นตัวเลข'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newId = DateTime.now().millisecondsSinceEpoch.toString();
              await _firestoreService.addTable(CanteenTable(
                id: newId,
                name: nameController.text.trim(),
                location: locationController.text.trim(),
                capacity: int.parse(capacityController.text.trim()),
              ));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['จองโต๊ะอาหาร', 'สถานที่โรงอาหาร', 'ข้อมูลส่วนตัว'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          if (_isAdmin && _currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'สร้างโต๊ะเริ่มต้น 4 โต๊ะต่อสถานที่ (คละ 2,4,5,6)',
              onPressed: () => _confirmSeedDefaultTables(context),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: _pages[_currentIndex],
      floatingActionButton: (_currentIndex == 0 && _isAdmin)
          ? FloatingActionButton(
              onPressed: () => _showAddTableDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.table_restaurant), label: 'จองโต๊ะ'),
          NavigationDestination(
              icon: Icon(Icons.location_on), label: 'สถานที่'),
          NavigationDestination(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}

class _TableListView extends StatefulWidget {
  final FirestoreService firestoreService;
  final AuthService authService;
  final bool isAdmin;

  const _TableListView({
    required this.firestoreService,
    required this.authService,
    this.isAdmin = false,
  });

  @override
  State<_TableListView> createState() => _TableListViewState();
}

class _TableListViewState extends State<_TableListView> {
  bool _showAvailableOnly = false;

  Future<void> _handleBook(BuildContext context, String tableId) async {
    final user = widget.authService.currentUser;
    if (user == null) return;

    final latestName = await widget.authService.getLatestDisplayName(user.uid);

    final success = await widget.firestoreService.bookTable(
      tableId: tableId,
      uid: user.uid,
      userName: latestName,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(success ? 'จองโต๊ะสำเร็จ' : 'โต๊ะนี้เพิ่งถูกจองไปแล้ว')),
      );
    }
  }

  Future<void> _handleCancel(BuildContext context, String tableId) async {
    await widget.firestoreService.cancelBooking(tableId);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ยกเลิกการจองแล้ว')));
    }
  }

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
      await widget.firestoreService.deleteTable(table.id);
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

  @override
  Widget build(BuildContext context) {
    final myUid = widget.authService.currentUser?.uid;

    return StreamBuilder(
      stream: widget.firestoreService.tablesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }

        final allTables = snapshot.data ?? [];
        final availableCount = allTables.where((t) => !t.isBooked).length;

        final sortedTables = [
          ...allTables
        ]..sort((a, b) => a.isBooked == b.isBooked ? 0 : (a.isBooked ? 1 : -1));

        final displayedTables = _showAvailableOnly
            ? sortedTables.where((t) => !t.isBooked).toList()
            : sortedTables;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            const MenuOfTheDayCard(),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              color: Colors.green.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.event_seat, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ว่าง $availableCount จาก ${allTables.length} โต๊ะ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  FilterChip(
                    label: const Text('เฉพาะโต๊ะว่าง'),
                    selected: _showAvailableOnly,
                    onSelected: (value) =>
                        setState(() => _showAvailableOnly = value),
                  ),
                ],
              ),
            ),
            if (allTables.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.table_restaurant_outlined,
                          size: 64, color: Colors.deepOrange),
                      const SizedBox(height: 14),
                      const Text(
                        'ยังไม่มีโต๊ะในระบบ',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'กดปุ่มด้านล่างเพื่อเพิ่มโต๊ะเริ่มต้น 4 โต๊ะต่อสถานที่ (คละที่นั่ง 2, 4, 5, 6 รวม 12 โต๊ะ)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text(
                            'สร้าง 4 โต๊ะต่อสถานที่ (คละ 2, 4, 5, 6)'),
                        onPressed: () async {
                          await widget.firestoreService.seedDefaultTables();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'สร้างโต๊ะเริ่มต้น 4 โต๊ะต่อสถานที่เรียบร้อยแล้ว (12 โต๊ะ)'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              )
            else if (displayedTables.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('ไม่พบโต๊ะที่ตรงเงื่อนไข')),
              )
            else
              ...displayedTables.map((table) => TableCard(
                    table: table,
                    isMine: table.bookedByUid == myUid,
                    isAdmin: widget.isAdmin,
                    onBook: () => _handleBook(context, table.id),
                    onCancel: () => _handleCancel(context, table.id),
                    onDelete: () => _handleDeleteTable(context, table),
                  )),
          ],
        );
      },
    );
  }
}
