import 'package:flutter/material.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class PaginatedDataView extends StatelessWidget {
  final List<Widget> children;
  final int itemsPerPage;
  final bool isLoading;
  final ScrollController scrollController;
  final Function() onLoadMore;
  final bool hasMoreData;

  const PaginatedDataView({
    super.key,
    required this.children,
    this.itemsPerPage = 10,
    this.isLoading = false,
    required this.scrollController,
    required this.onLoadMore,
    required this.hasMoreData,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!isLoading &&
            hasMoreData &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          onLoadMore();
        }
        return true;
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < children.length) {
                  return children[index];
                }
                if (isLoading && hasMoreData) {
                  return const SkeletonPaginationLoader();
                }
                return null;
              },
              childCount: children.length + (isLoading && hasMoreData ? 1 : 0),
            ),
          ),
        ],
      ),
    );
  }
}

/// Contrôleur de pagination (sans GetX). Gérer le cycle de vie (dispose) côté appelant.
class PaginationController {
  final int itemsPerPage;
  int currentPage = 1;
  bool isLoading = false;
  bool hasMoreData = true;
  final ScrollController scrollController = ScrollController();

  PaginationController({this.itemsPerPage = 10});

  void resetPagination() {
    currentPage = 1;
    hasMoreData = true;
  }

  Future<void> loadNextPage() async {
    if (isLoading || !hasMoreData) return;
    isLoading = true;
    await loadData();
    isLoading = false;
  }

  Future<void> loadData() async {
    // À implémenter dans les classes dérivées
  }

  void dispose() {
    scrollController.dispose();
  }
}
