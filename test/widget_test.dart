import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_booking_app/models/canteen_table.dart';
import 'package:canteen_booking_app/widgets/table_card.dart';

void main() {
  testWidgets('TableCard displays table info and delete button for admin',
      (WidgetTester tester) async {
    const table = CanteenTable(
      id: 'table_1',
      name: 'โต๊ะ A1',
      location: 'โรงอาหารตึก 1 ชั้น 1',
      capacity: 4,
    );

    bool deleteTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TableCard(
            table: table,
            isMine: false,
            isAdmin: true,
            onBook: () {},
            onCancel: () {},
            onDelete: () {
              deleteTapped = true;
            },
          ),
        ),
      ),
    );

    // ตรวจสอบชื่อโต๊ะและจำนวนที่นั่ง
    expect(find.text('โต๊ะ A1'), findsOneWidget);
    expect(find.text('นั่งได้ 4 ที่'), findsOneWidget);

    // แอดมินต้องเห็นปุ่มลบโต๊ะ
    final deleteButton = find.byTooltip('ลบโต๊ะ (Admin)');
    expect(deleteButton, findsOneWidget);

    await tester.tap(deleteButton);
    expect(deleteTapped, isTrue);
  });
}
