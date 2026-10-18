import 'package:delivery_app/features/detail_delivery/detail_delivery_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> start(WidgetTester tester, {double width = 390}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: DetailDeliveryPage())),
  );
  await tester.pumpAndSettle();
}

Future<void> pressInList(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.scrollUntilVisible(
    target,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> role(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Chọn vai trò'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Cancellation requires confirmation and updates history', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Theo dõi chuyến'));
    await tester.pumpAndSettle();
    await pressInList(tester, 'Hủy chuyến');
    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Hủy chuyến'), findsOneWidget);
    await tester.tap(find.text('Hủy chuyến'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Hủy chuyến'));
    await tester.pumpAndSettle();
    expect(find.text('Lịch sử chuyến đi'), findsOneWidget);
    expect(find.text('Theo dõi chuyến'), findsNothing);
    await tester.tap(find.text('Đang thực hiện'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có chuyến phù hợp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Driver completion updates customer history before rating', (
    tester,
  ) async {
    await start(tester);
    await role(tester, 'Tài xế');
    expect(find.text('Nguyễn Minh An'), findsOneWidget);
    await pressInList(tester, 'Xác nhận đã lấy hàng');
    expect(find.text('Hoàn tất chuyến đi'), findsOneWidget);
    await pressInList(tester, 'Hoàn tất chuyến đi');
    await tester.tap(find.text('Đã giao và thu tiền'));
    await tester.pumpAndSettle();
    await role(tester, 'Khách hàng');
    expect(find.text('Theo dõi chuyến'), findsNothing);
    await tester.tap(find.text('Chuyến hiện tại'));
    await tester.pumpAndSettle();
    await pressInList(tester, 'Đánh giá tài xế');
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Gửi đánh giá'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('5 sao'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi đánh giá'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn đã đánh giá 5 sao'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Completed filter opens the correct historical trip', (
    tester,
  ) async {
    await start(tester);
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Hoàn tất'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Hoàn tất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('18 Lê Lợi, Quận 1'));
    await tester.pumpAndSettle();
    expect(find.text('Mã chuyến NS2310'), findsOneWidget);
    expect(find.text('Phạm Quốc Huy'), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại lịch sử'));
    await tester.pumpAndSettle();
    expect(find.text('Chuyến đã hoàn tất'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Three screens support narrow displays and larger text', (
    tester,
  ) async {
    await start(tester, width: 320);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await pressInList(tester, 'Theo dõi chuyến');
    expect(find.text('Mã chuyến NS2408'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await role(tester, 'Tài xế');
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
