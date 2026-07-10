import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/widgets.dart';

/// Search query state with 350ms debounce.
final searchQueryProvider =
    StateNotifierProvider<SearchQueryNotifier, String>((ref) {
  return SearchQueryNotifier();
});

class SearchQueryNotifier extends StateNotifier<String> {
  SearchQueryNotifier() : super('');
  Timer? _t;

  void set(String v) {
    state = v;
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 350), () {});
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctl = TextEditingController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppTextField(
                controller: _ctl,
                hint: 'Search your photos, sessions, locations...',
                prefixIcon: const Icon(Icons.search),
                onChanged: (v) => ref.read(searchQueryProvider.notifier).set(v),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _ctl.clear();
                          ref.read(searchQueryProvider.notifier).set('');
                        },
                      ),
              ),
            ),
            Expanded(
              child: query.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.search,
                      title: 'Search your library',
                      description:
                          'Find past sessions by location, subject, or date.',
                    )
                  : const AppEmptyState(
                      icon: Icons.image_not_supported_outlined,
                      title: 'No matches yet',
                      description:
                          'Try a different keyword — your library will grow '
                          'as you capture more sessions.',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
