import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:system_design/common.dart';

import '../constants/log_tag_constant.dart';
import 'analytics_parameter_utils.dart';

/// Every analytics event the app sends, as a typed method.
///
/// **Nothing calls `FirebaseAnalytics` directly and nothing types an event
/// name at a call site.** The full inventory of what this product reports
/// about its users is this one file, which is the only way that inventory
/// stays reviewable.
///
/// **No credential, no buyer name, no address, no marketplace token, and no
/// item title ever becomes a parameter** (hard rule 9). Analytics is a
/// third-party dashboard; a title like "Nike Air Max 90" is the seller's
/// business, and a buyer's name is somebody else's. Counts, ids, enum names
/// and boolean flags only. Boolean flags are converted to `1` or `0` before
/// Firebase receives them because its Flutter SDK rejects Dart `bool` values.
///
/// A no-op until `bootstrap` attaches Firebase, exactly like `CrashReporter`:
/// the app runs with no backend and every call here is silently dropped
/// rather than throwing `[core/no-app]`.
abstract class AppAnalytics {
  /// The instance every feature calls. Replaced once by [attach].
  static AppAnalytics instance = const _NoopAnalytics();

  static void attach(FirebaseAnalytics analytics) {
    instance = _FirebaseAppAnalytics(analytics);
    SdLogger.info(LogTagConstant.analytics, 'Analytics attached');
  }

  // --- Navigation ---

  /// One of the five bottom tabs came to the front.
  ///
  /// **The router cannot report this.** The tabs are branches of a
  /// `StatefulShellRoute.indexedStack`, so switching one pushes no route and a
  /// navigator observer sees nothing — without this call, tab analytics read
  /// as if nobody ever opens Inventory. `AppShell` is the only place that sees
  /// the change.
  ///
  /// [tab] is a stable identifier from `NavTabConstant`, never a localized
  /// label: a name that changes with the locale splits one tab into two series.
  void tabViewed({required String tab});

  /// A screen the router opened — anything that is not a tab's own root.
  ///
  /// [screen] is the route's template (`/inventory/item/:itemId`), never the
  /// location: a location carries the record id, which splits one screen into
  /// a series per record and puts ids in a third-party report.
  void screenViewed({required String screen});

  /// A tapped push opened the app. [type] is the server's notification kind.
  void pushOpened({required String type});

  // --- Session ---

  /// Ties every later event to the account, or clears it on sign-out.
  ///
  /// A Firebase uid and nothing else — the same contract as
  /// `SdCrashReporter.setUserId` (hard rule 9).
  void setUserId(String? uid);

  void signedIn({required String provider});

  void signedOut();

  /// [skipped] tells reading the intro from leaving it; [page] is how far the
  /// seller got, counted from one.
  void onboardingCompleted({required bool skipped, required int page});

  void workspaceCreated({required String currency, required String country});

  void workspaceSwitched();

  /// A guest's local records went into an account — the moment guest mode
  /// turns into a signed-in seller (hard rule 1).
  void guestRecordsSynced();

  /// [role] is a `MemberRole` name. Never the address it went to (hard rule 9).
  void teammateInvited({required String role});

  void invitationAccepted();

  // --- Inventory ---

  /// [viaQuickAdd] tells the fast path from the full form. It is the single
  /// most important number in this file: hard rule 2 says the product's speed
  /// rests on Quick Add, and this is how anyone finds out whether sellers
  /// actually use it.
  void itemCreated({required bool viaQuickAdd, required bool hasPhoto});

  void itemListed({required String marketplace});

  void itemSold({required String marketplace, required bool hadCost});

  /// [count] is what makes bulk worth having built (hard rule 16).
  void bulkAction({required String action, required int count});

  // --- Orders ---

  void orderShipped({required bool hasTracking});

  void returnOpened();

  /// [outcome] is the `OfferStatus` the seller chose.
  void offerResponded({required String outcome});

  /// Payouts recorded in one sitting. [viaImport] tells a marketplace CSV from
  /// typed figures — how often sellers reach for the import is the question.
  void payoutsRecorded({required int count, required bool viaImport});

  // --- Money in and out ---

  void expenseRecorded({required String category});

  void purchaseRecorded({required bool hasSource});

  void reportExported({required String kind});

  // --- Subscription (plan §27) ---
  //
  // Plan and period names only. **No price, no product id, no receipt and no
  // store transaction** (hard rule 9) — RevenueCat's own dashboard is where
  // revenue is read, and a receipt in an analytics payload is a credential in
  // a third-party dashboard.

  /// A seller hit a limit or a locked feature. The share of sellers who see
  /// this and never upgrade is what says whether the free tier is the wrong
  /// size, and no other event can answer it.
  void paywallShown({required String reason, required String fromPlan});

  void subscriptionPurchaseStarted({
    required String plan,
    required String period,
  });

  void subscriptionActivated({required String plan});
}

class _NoopAnalytics implements AppAnalytics {
  const _NoopAnalytics();

  @override
  void tabViewed({required String tab}) {}

  @override
  void screenViewed({required String screen}) {}

  @override
  void pushOpened({required String type}) {}

  @override
  void setUserId(String? uid) {}

  @override
  void signedIn({required String provider}) {}

  @override
  void signedOut() {}

  @override
  void onboardingCompleted({required bool skipped, required int page}) {}

  @override
  void workspaceCreated({required String currency, required String country}) {}

  @override
  void workspaceSwitched() {}

  @override
  void guestRecordsSynced() {}

  @override
  void teammateInvited({required String role}) {}

  @override
  void invitationAccepted() {}

  @override
  void itemCreated({required bool viaQuickAdd, required bool hasPhoto}) {}

  @override
  void itemListed({required String marketplace}) {}

  @override
  void itemSold({required String marketplace, required bool hadCost}) {}

  @override
  void bulkAction({required String action, required int count}) {}

  @override
  void orderShipped({required bool hasTracking}) {}

  @override
  void returnOpened() {}

  @override
  void offerResponded({required String outcome}) {}

  @override
  void payoutsRecorded({required int count, required bool viaImport}) {}

  @override
  void expenseRecorded({required String category}) {}

  @override
  void purchaseRecorded({required bool hasSource}) {}

  @override
  void reportExported({required String kind}) {}

  @override
  void paywallShown({required String reason, required String fromPlan}) {}

  @override
  void subscriptionPurchaseStarted({
    required String plan,
    required String period,
  }) {}

  @override
  void subscriptionActivated({required String plan}) {}
}

class _FirebaseAppAnalytics implements AppAnalytics {
  const _FirebaseAppAnalytics(this._analytics);

  final FirebaseAnalytics _analytics;

  // Firebase's own `screen_view`, so the tabs land in the standard screen
  // report rather than a custom event nobody's dashboard knows about.
  @override
  void tabViewed({required String tab}) =>
      _report('screen_view', _analytics.logScreenView(screenName: tab));

  @override
  void screenViewed({required String screen}) =>
      _report('screen_view', _analytics.logScreenView(screenName: screen));

  @override
  void pushOpened({required String type}) =>
      _send('push_opened', <String, Object>{'type': type});

  @override
  void setUserId(String? uid) =>
      _report('set_user_id', _analytics.setUserId(id: uid));

  @override
  void signedIn({required String provider}) =>
      _send('sign_in', <String, Object>{'provider': provider});

  @override
  void signedOut() => _send('sign_out', const <String, Object>{});

  @override
  void onboardingCompleted({required bool skipped, required int page}) => _send(
    'onboarding_completed',
    <String, Object>{'skipped': skipped, 'page': page},
  );

  @override
  void workspaceCreated({required String currency, required String country}) =>
      _send('workspace_created', <String, Object>{
        'currency': currency,
        'country': country,
      });

  @override
  void workspaceSwitched() =>
      _send('workspace_switched', const <String, Object>{});

  @override
  void guestRecordsSynced() =>
      _send('guest_records_synced', const <String, Object>{});

  @override
  void teammateInvited({required String role}) =>
      _send('teammate_invited', <String, Object>{'role': role});

  @override
  void invitationAccepted() =>
      _send('invitation_accepted', const <String, Object>{});

  @override
  void itemCreated({required bool viaQuickAdd, required bool hasPhoto}) =>
      _send('item_created', <String, Object>{
        'via_quick_add': viaQuickAdd,
        'has_photo': hasPhoto,
      });

  @override
  void itemListed({required String marketplace}) =>
      _send('item_listed', <String, Object>{'marketplace': marketplace});

  @override
  void itemSold({required String marketplace, required bool hadCost}) =>
      _send('item_sold', <String, Object>{
        'marketplace': marketplace,
        // Whether profit was computable. The share of sales where it is not
        // is the health metric for the whole "insight" half of the product.
        'had_cost': hadCost,
      });

  @override
  void bulkAction({required String action, required int count}) =>
      _send('bulk_action', <String, Object>{'action': action, 'count': count});

  @override
  void orderShipped({required bool hasTracking}) =>
      _send('order_shipped', <String, Object>{'has_tracking': hasTracking});

  @override
  void returnOpened() => _send('return_opened', const <String, Object>{});

  @override
  void offerResponded({required String outcome}) =>
      _send('offer_responded', <String, Object>{'outcome': outcome});

  @override
  void payoutsRecorded({required int count, required bool viaImport}) => _send(
    'payouts_recorded',
    <String, Object>{'count': count, 'via_import': viaImport},
  );

  @override
  void expenseRecorded({required String category}) =>
      _send('expense_recorded', <String, Object>{'category': category});

  @override
  void purchaseRecorded({required bool hasSource}) =>
      _send('purchase_recorded', <String, Object>{'has_source': hasSource});

  @override
  void reportExported({required String kind}) =>
      _send('report_exported', <String, Object>{'kind': kind});

  @override
  void paywallShown({required String reason, required String fromPlan}) =>
      _send('paywall_shown', <String, Object>{
        'reason': reason,
        'from_plan': fromPlan,
      });

  @override
  void subscriptionPurchaseStarted({
    required String plan,
    required String period,
  }) => _send('subscription_purchase_started', <String, Object>{
    'plan': plan,
    'period': period,
  });

  @override
  void subscriptionActivated({required String plan}) =>
      _send('subscription_activated', <String, Object>{'plan': plan});

  void _send(String name, Map<String, Object> parameters) => _report(
    name,
    _analytics.logEvent(
      name: name,
      parameters: AnalyticsParameterUtils.firebaseSafe(parameters),
    ),
  );

  /// Fire and forget, and never let a failed event break the action that
  /// raised it — but log it, because a caught error nobody logs is a failure
  /// nobody can fix (hard rule 8).
  void _report(String name, Future<void> sent) {
    sent.catchError((Object error, StackTrace stackTrace) {
      SdLogger.error(
        LogTagConstant.analytics,
        'Analytics event failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'event': name},
      );
    });
  }
}
