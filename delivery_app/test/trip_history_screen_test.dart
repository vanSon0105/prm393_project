import 'dart:convert';

import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/app_state.dart';
import 'package:delivery_app/features/app_view_model.dart';
import 'package:delivery_app/features/detail_delivery/detail_delivery_page.dart';
import 'package:delivery_app/features/driver_rating/data/trip_rating_repository.dart';
import 'package:delivery_app/features/trip/data/models/trip_history_model.dart';
import 'package:delivery_app/features/trip/data/repositories/trip_history_remote_repository.dart';
import 'package:delivery_app/features/trip/presentation/providers/trip_history_provider.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic>? _translations;

class _TestTranslations extends AssetLoader {
  const _TestTranslations();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      _translations!;
}

class _HistoryRepository extends TripHistoryRemoteRepository {
  _HistoryRepository() : super(ApiProvider(Dio()));

  final calls = <(int, int)>[];
  late final ratingRepository = _RecordingRatingRepository(this);
  int? rating;
  String? reviewComment;

  @override
  Future<TripHistoryPageData> getHistory({
    required int profileId,
    int limit = 20,
    int offset = 0,
  }) async {
    calls.add((profileId, offset));
    return TripHistoryPageData(
      entries: [
        TripHistoryEntry(
          tripId: offset == 0 ? 31 : 30,
          statusId: offset == 0 ? 4 : 5,
          customerName: 'Customer A',
          driverName: offset == 0 ? 'Driver B' : null,
          pickupLatitude: 21.03,
          pickupLongitude: 105.85,
          destinationLatitude: 21.04,
          destinationLongitude: 105.86,
          distanceKm: offset == 0 ? 8 : null,
          price: offset == 0 ? 42000 : null,
          reviewVote: offset == 0 ? rating : null,
          reviewComment: offset == 0 ? reviewComment : null,
        ),
      ],
      hasMore: offset == 0,
    );
  }
}

class _RecordingRatingRepository extends TripRatingRepository {
  _RecordingRatingRepository(this.history) : super(ApiProvider(Dio()));

  final _HistoryRepository history;
  int? submittedTripId;
  String? submittedComment;
  bool fail = false;
  bool duplicate = false;

  @override
  Future<void> submit({
    required int tripId,
    required int vote,
    required String comment,
  }) async {
    if (duplicate) throw const TripAlreadyRatedException();
    if (fail) throw StateError('Review unavailable');
    submittedTripId = tripId;
    submittedComment = comment;
    history.rating = vote;
  }
}

Future<void> _start(
  WidgetTester tester,
  _HistoryRepository repository, {
  Role role = Role.customer,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US')],
      startLocale: const Locale('en', 'US'),
      path: 'resources/langs',
      assetLoader: const _TestTranslations(),
      child: Builder(
        builder: (context) => ProviderScope(
          overrides: [
            appViewModelProvider.overrideWithValue(
              AppState(role: role, profileId: 7),
            ),
            tripHistoryRepositoryProvider.overrideWithValue(repository),
            tripRatingRepositoryProvider.overrideWithValue(
              repository.ratingRepository,
            ),
          ],
          child: MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const DetailDeliveryPage(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    _translations = Map<String, dynamic>.from(
      jsonDecode(await rootBundle.loadString('resources/langs/en-US.json'))
          as Map,
    );
  });

  testWidgets('customer history uses profile ID and loads another page', (
    tester,
  ) async {
    final repository = _HistoryRepository();
    await _start(tester, repository);

    expect(repository.calls, [(7, 0)]);
    expect(find.text('Trip 31'), findsOneWidget);
    expect(find.text('Driver B'), findsOneWidget);
    expect(find.byTooltip('Choose role'), findsNothing);
    expect(find.byTooltip('Back to map'), findsNothing);

    await tester.tap(find.text('Load more trips'));
    await tester.pumpAndSettle();
    expect(repository.calls, [(7, 0), (7, 1)]);
    expect(find.text('Trip 30'), findsOneWidget);

    await tester.tap(find.text('Trip 30'));
    await tester.pumpAndSettle();
    expect(find.text('No driver assigned'), findsOneWidget);
    expect(find.text('Unavailable'), findsWidgets);
    await tester.tap(find.byTooltip('Back to history'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Refresh trip history'));
    await tester.pumpAndSettle();
    expect(repository.calls, [(7, 0), (7, 1), (7, 0)]);
    expect(find.text('Trip 30'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('driver history shows customer details', (tester) async {
    final repository = _HistoryRepository();
    await _start(tester, repository, role: Role.driver);

    expect(repository.calls, [(7, 0)]);
    expect(find.text('Customer A'), findsOneWidget);
    expect(find.byTooltip('Choose role'), findsNothing);
    await tester.tap(find.text('Trip 31'));
    await tester.pumpAndSettle();
    expect(find.text('No customer rating yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('driver can read stars and comment for a completed trip', (
    tester,
  ) async {
    final repository = _HistoryRepository()
      ..rating = 4
      ..reviewComment = 'Safe ride';
    await _start(tester, repository, role: Role.driver);

    expect(find.text('4/5 stars'), findsOneWidget);
    await tester.tap(find.text('Trip 31'));
    await tester.pumpAndSettle();
    expect(find.text('Customer rating'), findsOneWidget);
    expect(find.text('4/5 stars'), findsOneWidget);
    expect(find.text('Customer comment'), findsOneWidget);
    expect(find.text('Safe ride'), findsOneWidget);
    expect(find.text('Rate driver'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('customer can skip rating and submit later from history', (
    tester,
  ) async {
    final repository = _HistoryRepository();
    await _start(tester, repository);

    await tester.tap(find.text('Trip 31'));
    await tester.pumpAndSettle();
    expect(find.text('Rate driver'), findsOneWidget);

    await tester.tap(find.text('Rate driver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(repository.rating, isNull);
    expect(find.text('Rate driver'), findsOneWidget);

    await tester.tap(find.text('Rate driver'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(TextField), 250);
    await tester.enterText(find.byType(TextField), 'Great trip');
    repository.ratingRepository.fail = true;
    await tester.tap(find.text('Submit rating'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not submit your rating. Please try again.'),
      findsOneWidget,
    );
    expect(repository.rating, isNull);
    repository.ratingRepository.fail = false;
    await tester.tap(find.text('Submit rating'));
    await tester.pumpAndSettle();

    expect(repository.ratingRepository.submittedTripId, 31);
    expect(repository.ratingRepository.submittedComment, 'Great trip');
    await tester.tap(find.text('Trip 31'));
    await tester.pumpAndSettle();
    expect(find.text('You rated 5 stars'), findsOneWidget);
    expect(find.text('Rate driver'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('already rated trip closes the form and prevents another vote', (
    tester,
  ) async {
    final repository = _HistoryRepository();
    repository.ratingRepository.duplicate = true;
    await _start(tester, repository);

    await tester.tap(find.text('Trip 31'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rate driver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit rating'));
    await tester.pumpAndSettle();

    expect(find.text('This trip has already been rated.'), findsOneWidget);
    expect(repository.rating, isNull);
    await tester.tap(find.text('Trip 31'));
    await tester.pumpAndSettle();
    expect(find.text('Rate driver'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
