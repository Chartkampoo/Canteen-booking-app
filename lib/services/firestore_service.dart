import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/canteen_table.dart';

class FirestoreService {
  final CollectionReference _tables =
      FirebaseFirestore.instance.collection('canteen_tables');

  Stream<List<CanteenTable>> get tablesStream {
    return _tables.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              CanteenTable.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Stream<List<CanteenTable>> tablesByLocation(String location) {
    return _tables.where('location', isEqualTo: location).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => CanteenTable.fromMap(
                doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addTable(CanteenTable table) async {
    await _tables.doc(table.id).set(table.toMap());
  }

  Future<void> deleteTable(String tableId) async {
    await _tables.doc(tableId).delete();
  }

  Future<void> seedDefaultTables() async {
    const locations = [
      {'name': 'โรงอาหารตึก 1 ชั้น 1', 'prefix': 'A'},
      {'name': 'โรงอาหารตึก 1 ชั้น 2', 'prefix': 'B'},
      {'name': 'โรงอาหารตึก 2 ชั้น 1', 'prefix': 'C'},
    ];
    const capacities = [2, 4, 5, 6];

    final batch = FirebaseFirestore.instance.batch();

    for (final loc in locations) {
      final locName = loc['name']!;
      final prefix = loc['prefix']!;

      for (int i = 0; i < capacities.length; i++) {
        final tableNum = i + 1;
        final docId = '${prefix.toLowerCase()}_table_$tableNum';
        final docRef = _tables.doc(docId);

        batch.set(
          docRef,
          {
            'name': 'โต๊ะ $prefix$tableNum',
            'location': locName,
            'capacity': capacities[i],
            'isBooked': false,
            'bookedByUid': null,
            'bookedByName': null,
          },
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
  }

  Future<void> seedTablesForLocation(String locationName) async {
    String prefix = 'A';
    if (locationName.contains('ตึก 1 ชั้น 2')) {
      prefix = 'B';
    } else if (locationName.contains('ตึก 2')) {
      prefix = 'C';
    }

    const capacities = [2, 4, 5, 6];
    final batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < capacities.length; i++) {
      final tableNum = i + 1;
      final docId = '${prefix.toLowerCase()}_table_$tableNum';
      final docRef = _tables.doc(docId);

      batch.set(
        docRef,
        {
          'name': 'โต๊ะ $prefix$tableNum',
          'location': locationName,
          'capacity': capacities[i],
          'isBooked': false,
          'bookedByUid': null,
          'bookedByName': null,
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<bool> bookTable({
    required String tableId,
    required String uid,
    required String userName,
  }) async {
    final docRef = _tables.doc(tableId);
    return FirebaseFirestore.instance.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data() as Map<String, dynamic>;
      if (data['isBooked'] == true) {
        return false;
      }
      transaction.update(docRef, {
        'isBooked': true,
        'bookedByUid': uid,
        'bookedByName': userName,
      });
      return true;
    });
  }

  Future<void> cancelBooking(String tableId) async {
    await _tables.doc(tableId).update({
      'isBooked': false,
      'bookedByUid': null,
      'bookedByName': null,
    });
  }

  Future<void> updateBookedUserName({
    required String uid,
    required String newName,
  }) async {
    final snapshot = await _tables.where('bookedByUid', isEqualTo: uid).get();
    if (snapshot.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'bookedByName': newName});
    }
    await batch.commit();
  }
}
