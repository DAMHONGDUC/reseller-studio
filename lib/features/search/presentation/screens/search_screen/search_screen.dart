import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../providers.dart';

/// Global search (plan §21) — items, orders, listings and sources at once.
///
/// **One list, not four tabs.** A seller searching a tracking number does not
/// know or care which collection it lives in; making them pick first is asking
/// them to answer the question they came to ask.
///
/// The field is focused on arrival: this screen exists to be typed into, and
/// a keyboard the seller has to summon costs a tap on every search.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    // After the first frame: writing to a provider during build is what
    // Riverpod asserts on, and the query has to start empty or the screen
    // opens showing the last search's results.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(SearchHit hit) {
    switch (hit.kind) {
      case SearchHitKind.item:
      case SearchHitKind.listing:
        context.push(AppRoutes.item(hit.id));
      case SearchHitKind.order:
        context.push(AppRoutes.order(hit.id));
      case SearchHitKind.source:
        context.push(AppRoutes.sources);
    }
  }

  static IconData _iconFor(SearchHitKind kind) => switch (kind) {
    SearchHitKind.item => Symbols.inventory_2_rounded,
    SearchHitKind.order => Symbols.receipt_long_rounded,
    SearchHitKind.listing => Symbols.sell_rounded,
    SearchHitKind.source => Symbols.storefront_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final String query = ref.watch(searchQueryProvider);
    final List<SearchHit> hits = ref.watch(searchResultsProvider);

    return SdScaffoldV3(
      appBar: const SdAppBarV3(title: 'Search'),
      body: Column(
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV3.horizontal,
            ),
            child: SdSearchFieldV3(
              controller: _controller,
              // The screen exists to be typed into; a keyboard the seller has
              // to summon costs a tap on every search.
              autofocus: true,
              hint: 'Title, SKU, barcode, order or tracking number',
              clearTooltip: 'Clear search',
              onChanged: (String value) =>
                  ref.read(searchQueryProvider.notifier).update(value),
            ),
          ),
          Expanded(
            child: switch (hits) {
              _
                  when query.trim().length <
                      SearchConstant.minimumQueryLength =>
                const SdEmptyStateV3(
                  icon: Symbols.search_rounded,
                  title: 'Search everything',
                  message:
                      'Items, orders, listings and sources — type at least '
                      'two characters.',
                ),
              _ when hits.isEmpty => const SdEmptyStateV3(
                icon: Symbols.search_off_rounded,
                title: 'Nothing matches',
                message: 'Try a shorter piece of the name or code.',
              ),
              _ => ListView(
                padding: SdContentPaddingV3.screen(context),
                children: <Widget>[
                  AppListCard(
                    children: hits
                        .map(
                          (SearchHit hit) => AppListRow(
                            title: hit.title,
                            subtitle: hit.subtitle,
                            icon: _iconFor(hit.kind),
                            onTap: () => _open(hit),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}
