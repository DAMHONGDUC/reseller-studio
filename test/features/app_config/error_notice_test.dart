import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart';
import 'package:reseller_studio/features/app_config/data/dtos/app_config_dto.dart';
import 'package:reseller_studio/features/app_config/domain/entities/app_config.dart';
import 'package:reseller_studio/features/app_config/domain/entities/app_error_notice.dart';
import 'package:reseller_studio/features/app_config/domain/enums/app_notice_type.dart';
import 'package:reseller_studio/features/app_config/domain/repositories/app_config_repository.dart';
import 'package:reseller_studio/features/app_config/presentation/widgets/error_notice_gate.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The one field in `app_config` that can take the app away from every seller
/// at once. What has to hold is the direction it fails in: a block nobody
/// typed, mistyped, or typed only half of leaves the app running.
class _FixedConfig implements AppConfigRepository {
  const _FixedConfig(this.config);

  final AppConfig config;

  @override
  Stream<AppConfig> watch() => Stream<AppConfig>.value(config);
}

void main() {
  /// The entity the DTO reads out of a document holding [errorView] under
  /// `error_view` — the hand-typed shape, not the Dart one.
  AppErrorNotice noticeFrom(Object? errorView) => AppConfigDto.fromData(
    <String, Object?>{'error_view': errorView},
  ).errorNotice;

  const AppErrorNotice live = AppErrorNotice(
    enabled: true,
    title: 'Reseller Studio is paused',
    subtitle1: 'We are moving your data.',
    subtitle2: 'Try again in about an hour.',
    type: AppNoticeType.warning,
  );

  group('what reaches the screen', () {
    test('the fallback shows nothing', () {
      expect(AppConfig.fallback.errorNotice.shows, isFalse);
    });

    test('a switch on with words behind it shows', () {
      expect(live.shows, isTrue);
    });

    test('a switch on with no title does not', () {
      // A notice with no words is a blank screen with no way out — worse than
      // the state somebody turned it on to explain.
      expect(
        const AppErrorNotice(enabled: true, subtitle1: 'Why').shows,
        isFalse,
      );
    });

    test('words with the switch off do not', () {
      // The owner drafting the sentence is not the owner sending it.
      expect(
        const AppErrorNotice(title: 'Paused', subtitle1: 'Why').shows,
        isFalse,
      );
    });
  });

  group('the document is read defensively', () {
    test('a missing block reads as nothing to show', () {
      expect(noticeFrom(null).shows, isFalse);
    });

    test('a block of the wrong type does too', () {
      expect(noticeFrom('on').shows, isFalse);
    });

    test('a switch that is not a bool does too', () {
      expect(
        noticeFrom(<String, Object?>{
          'enable': 'true',
          'title': 'Paused',
        }).shows,
        isFalse,
      );
    });

    test('the lines are trimmed, and a missing one is empty', () {
      final AppErrorNotice notice = noticeFrom(<String, Object?>{
        'enable': true,
        'title': '  Paused  ',
        'subtitle_1': 'We are moving your data.',
        'type': 'warning',
      });

      expect(notice.title, 'Paused');
      expect(notice.subtitle2, isEmpty);
      expect(notice.shows, isTrue);
    });

    test('an unreadable type is the louder one', () {
      // The field is called error_view, so a value nobody could type
      // correctly reads as an error rather than as a tip.
      expect(AppNoticeType.parse('WARNING'), AppNoticeType.warning);
      expect(AppNoticeType.parse('notice'), AppNoticeType.error);
      expect(AppNoticeType.parse(null), AppNoticeType.error);
      expect(AppNoticeType.parse(7), AppNoticeType.error);
    });
  });

  group('ErrorNoticeGate', () {
    Future<void> pumpGate(WidgetTester tester, AppConfig config) => pumpScreen(
      tester,
      const ErrorNoticeGate(child: Text('the app')),
      overrides: <Override>[
        appConfigRepositoryProvider.overrideWithValue(_FixedConfig(config)),
      ],
    );

    testWidgets('it hands the screen over while the notice is on', (
      WidgetTester tester,
    ) async {
      await pumpGate(tester, const AppConfig(errorNotice: live));
      await tester.pump();

      expect(find.text('Reseller Studio is paused'), findsOneWidget);
      expect(find.text('Try again in about an hour.'), findsOneWidget);
      // Nothing underneath is built, which is the difference from a sheet:
      // no router, no screens listening, no reads behind the glass.
      expect(find.text('the app'), findsNothing);
    });

    testWidgets('the app runs while it is off', (WidgetTester tester) async {
      await pumpGate(tester, AppConfig.fallback);
      await tester.pump();

      expect(find.text('the app'), findsOneWidget);
      expect(find.byType(SdErrorViewV3), findsNothing);
    });
  });
}
