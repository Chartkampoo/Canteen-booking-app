// หน้าข้อมูลส่วนตัว: อ่าน/แก้ไขข้อมูลจาก Firestore + Firebase Auth
// หัวข้อ 9: แสดงสถานะ Secure Storage (auth token ที่เก็บไว้อย่างเข้ารหัส)

import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _storageService = StorageService();
  final _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();

  AppUser? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _tokenPreview; // เก็บ token แบบตัดสั้นไว้โชว์ (ไม่โชว์เต็ม เพื่อความปลอดภัย)

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadTokenStatus();
  }

  Future<void> _loadProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final profile = await _authService.fetchProfile(user.uid);
    if (!mounted) return;
    setState(() {
      _profile = profile ??
          AppUser(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            studentId: '',
          );
      _nameController.text = _profile?.displayName ?? '';
      _studentIdController.text = _profile?.studentId ?? '';
      _isLoading = false;
    });
  }

  // หัวข้อ 9: อ่านค่าจาก Secure Storage มาโชว์สถานะ (ไม่โชว์ค่าจริงทั้งหมด)
  Future<void> _loadTokenStatus() async {
    final token = await _storageService.getAuthToken();
    if (!mounted) return;
    setState(() {
      _tokenPreview = (token != null && token.length > 12)
          ? '${token.substring(0, 12)}••••••••'
          : null;
    });
  }

  Future<void> _clearToken() async {
    await _storageService.clearAuthToken();
    await _loadTokenStatus();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ล้าง Secure Token แล้ว')));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _profile == null) return;

    setState(() => _isSaving = true);
    try {
      final updated = AppUser(
        uid: _profile!.uid,
        email: _profile!.email,
        displayName: _nameController.text.trim(),
        studentId: _studentIdController.text.trim(),
        isAdmin: _profile!.isAdmin,
      );
      await _authService.updateProfile(updated);
      // อัปเดตชื่อผู้จองบนโต๊ะที่กำลังจองอยู่ทั้งหมดให้เป็นชื่อล่าสุดทันที
      await _firestoreService.updateBookedUserName(
        uid: updated.uid,
        newName: updated.displayName,
      );
      if (mounted) {
        setState(() {
          _profile = updated;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_profile == null) {
      return const Center(child: Text('ไม่พบข้อมูลผู้ใช้'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: Colors.deepOrange.withValues(alpha: 0.15),
                child: Text(
                  _profile!.displayName.isNotEmpty
                      ? _profile!.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 32, color: Colors.deepOrange),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(_profile!.email, style: TextStyle(color: Colors.grey[600])),
            ),
            if (_profile!.isAdmin) ...[
              const SizedBox(height: 4),
              const Center(
                child: Chip(
                  label: Text('แอดมิน'),
                  avatar: Icon(Icons.verified_user, size: 18),
                ),
              ),
            ],
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อ-นามสกุล',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกชื่อ' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: 'รหัสนักศึกษา',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกรหัสนักศึกษา' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('บันทึกข้อมูล'),
            ),

            // --- หัวข้อ 9: สถานะ Secure Storage ---
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 8),
            const Text('ความปลอดภัย', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      _tokenPreview != null ? Icons.lock : Icons.lock_open,
                      color: _tokenPreview != null ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_tokenPreview != null
                              ? 'มี Auth Token เก็บไว้อย่างปลอดภัย'
                              : 'ยังไม่มี Token เก็บไว้'),
                          if (_tokenPreview != null)
                            Text(_tokenPreview!,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    if (_tokenPreview != null)
                      TextButton(onPressed: _clearToken, child: const Text('ล้าง')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}