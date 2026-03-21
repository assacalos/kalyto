import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget de base pour créer un effet de shimmer/skeleton
class Shimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const Shimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _ShimmerEffect(
          child: widget.child,
          baseColor: widget.baseColor,
          highlightColor: widget.highlightColor,
          progress: _controller.value,
        );
      },
    );
  }
}

class _ShimmerEffect extends StatelessWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final double progress;

  const _ShimmerEffect({
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [baseColor, highlightColor, baseColor],
          stops: [
            math.max(0.0, progress - 0.3),
            progress,
            math.min(1.0, progress + 0.3),
          ],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}

/// Skeleton pour une carte de statistique
class SkeletonCard extends StatelessWidget {
  final double? height;
  final EdgeInsets? padding;

  const SkeletonCard({super.key, this.height, this.padding});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Shimmer(
        child: Container(
          height: height ?? 150,
          padding: padding ?? const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 16),
              // Titre
              Container(
                width: 100,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              // Valeur
              Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton pour une grille de cartes
class SkeletonGrid extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsets padding;

  const SkeletonGrid({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 4,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      padding: padding,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      children: List.generate(itemCount, (index) => const SkeletonCard()),
    );
  }
}

/// Skeleton pour un élément de liste (ListTile)
class SkeletonListTile extends StatelessWidget {
  final bool hasLeading;
  final bool hasSubtitle;
  final EdgeInsets? margin;

  const SkeletonListTile({
    super.key,
    this.hasLeading = true,
    this.hasSubtitle = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.only(bottom: 8),
      child: Shimmer(
        child: ListTile(
          leading:
              hasLeading
                  ? Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  )
                  : null,
          title: Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          subtitle:
              hasSubtitle
                  ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  )
                  : null,
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton pour une liste de résultats de recherche
class SkeletonSearchResults extends StatelessWidget {
  final int itemCount;

  const SkeletonSearchResults({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(itemCount, (index) => const SkeletonListTile()),
      ),
    );
  }
}

/// Skeleton pour un tableau de données
class SkeletonTable extends StatelessWidget {
  final int rowCount;
  final int columnCount;

  const SkeletonTable({super.key, this.rowCount = 5, this.columnCount = 4});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Shimmer(
        child: Table(
          children: [
            // En-tête
            TableRow(
              children: List.generate(
                columnCount,
                (index) => Container(
                  padding: const EdgeInsets.all(12),
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[400]!),
                    ),
                  ),
                ),
              ),
            ),
            // Lignes
            ...List.generate(
              rowCount,
              (index) => TableRow(
                children: List.generate(
                  columnCount,
                  (index) => Container(
                    padding: const EdgeInsets.all(12),
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton pour un indicateur de chargement de pagination
class SkeletonPaginationLoader extends StatelessWidget {
  const SkeletonPaginationLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Shimmer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 100,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton pour un formulaire
class SkeletonFormField extends StatelessWidget {
  final bool hasLabel;
  final double height;

  const SkeletonFormField({super.key, this.hasLabel = true, this.height = 56});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Shimmer(
              child: Container(
                width: 100,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        Shimmer(
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }
}

/// Skeleton pour une page entière avec plusieurs sections
class SkeletonPage extends StatelessWidget {
  final bool hasAppBar;
  final bool hasSearchBar;
  final int listItemCount;

  const SkeletonPage({
    super.key,
    this.hasAppBar = true,
    this.hasSearchBar = false,
    this.listItemCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          hasAppBar
              ? AppBar(
                title: Shimmer(
                  child: Container(
                    width: 150,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              )
              : null,
      body: Column(
        children: [
          if (hasSearchBar)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SkeletonFormField(hasLabel: false),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listItemCount,
              itemBuilder: (context, index) => const SkeletonListTile(),
            ),
          ),
        ],
      ),
    );
  }
}
