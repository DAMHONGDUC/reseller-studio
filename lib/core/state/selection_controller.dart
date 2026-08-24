import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Which rows are ticked for a bulk action.
///
/// **Bulk is a first-class requirement, not a later nicety** (hard rule 16):
/// reprice, relist and archive are things a seller does to forty rows at
/// once, and a screen that only edits one row at a time is why people keep
/// using spreadsheets.
///
/// **In `core/` because Inventory and Listings both do it**, and the second
/// copy is the trigger for extracting rather than a later cleanup. What each
/// feature keeps is its own provider and its own "which records are these
/// ids", because those are the parts that know the entity.
///
/// Selection lives in a provider rather than a screen's `State` so an action
/// sheet — a different subtree, pushed on the root navigator — can read it
/// without the screen passing it down.
abstract class SelectionController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  bool get isActive => state.isNotEmpty;

  void toggle(String id) {
    final Set<String> next = Set<String>.of(state);

    if (!next.remove(id)) next.add(id);

    state = next;
  }

  void selectAll(Iterable<String> ids) => state = Set<String>.of(ids);

  void clear() => state = const <String>{};
}
