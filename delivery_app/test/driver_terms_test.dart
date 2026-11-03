import 'package:delivery_app/features/auth/register/driver_terms_provider.dart';
import 'package:delivery_app/features/auth/register/driver_terms_screen.dart';
import 'package:delivery_app/features/auth/register/driver_documents_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('Driver registration requires reading and accepting terms', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/driver-terms'),
              child: const Text('Đăng ký tài xế'),
            ),
          ),
        ),
        GoRoute(
          path: '/driver-terms',
          builder: (context, state) => const DriverTermsScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('Đăng ký tài xế'));
    await tester.pumpAndSettle();

    final continueButton = find.widgetWithText(
      ElevatedButton,
      'Tiếp tục đăng ký tài xế',
    );
    expect(tester.widget<ElevatedButton>(continueButton).onPressed, isNull);
    expect(container.read(driverTermsConsentProvider), isFalse);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(continueButton).onPressed, isNull);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(continueButton).onPressed, isNotNull);

    await tester.tap(continueButton);
    await tester.pumpAndSettle();
    expect(container.read(driverTermsConsentProvider), isTrue);
    expect(find.text('Đăng ký tài xế'), findsOneWidget);
  });

  testWidgets('Driver registration requires four document uploads', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Form(key: formKey, child: DriverDocumentsField()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ảnh giấy tờ *'), findsOneWidget);
    expect(find.text('Mặt trước CCCD'), findsOneWidget);
    expect(find.text('Mặt sau CCCD'), findsOneWidget);
    expect(find.text('Giấy phép lái xe mặt trước'), findsOneWidget);
    expect(find.text('Giấy phép lái xe mặt sau'), findsOneWidget);
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Vui lòng chọn đủ ảnh/tệp cho 4 mục giấy tờ.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
