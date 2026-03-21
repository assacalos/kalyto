import 'package:flutter/material.dart';

/// Liste avec pagination au scroll : appelle [onLoadMore] quand l'utilisateur
/// approche du bas, et affiche un indicateur de chargement en bas si [isLoadingMore].
class PaginatedListView extends StatelessWidget {
  final ScrollController scrollController;
  final VoidCallback onLoadMore;
  final bool hasNextPage;
  final bool isLoadingMore;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final double loadMoreTriggerOffset;

  const PaginatedListView({
    super.key,
    required this.scrollController,
    required this.onLoadMore,
    required this.hasNextPage,
    required this.isLoadingMore,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.loadMoreTriggerOffset = 200,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (!hasNextPage || isLoadingMore) return true;
        final metrics = notification.metrics;
        if (metrics.pixels >= metrics.maxScrollExtent - loadMoreTriggerOffset) {
          onLoadMore();
        }
        return true;
      },
      child: ListView.builder(
        controller: scrollController,
        padding: padding ?? const EdgeInsets.all(16),
        itemCount: itemCount + (hasNextPage || isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < itemCount) {
            return itemBuilder(context, index);
          }
          return _buildBottomLoader();
        },
      ),
    );
  }

  Widget _buildBottomLoader() {
    if (!isLoadingMore && !hasNextPage) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
