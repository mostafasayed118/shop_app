import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'product_grid.dart';

/// Pulsing placeholder grid shown while the catalogue loads.
///
/// Dependency-free shimmer: an [AnimationController] drives opacity between
/// 0.35 and 1 on grey skeleton cards.
class SkeletonGrid extends StatefulWidget {
  const SkeletonGrid({super.key, required this.crossAxisCount});

  final int crossAxisCount;

  @override
  State<SkeletonGrid> createState() => _SkeletonGridState();
}

class _SkeletonGridState extends State<SkeletonGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.35,
    upperBound: 1,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: kProductGridPadding,
        gridDelegate: productGridDelegate(widget.crossAxisCount),
        itemCount: math.max(widget.crossAxisCount, 2) * 2,
        itemBuilder: (context, index) => const _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: base.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _bar(base, width: 80, height: 12),
          const SizedBox(height: 8),
          _bar(base, width: double.infinity, height: 14),
          const SizedBox(height: 12),
          _bar(base, width: 64, height: 28),
        ],
      ),
    );
  }

  Widget _bar(Color base, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
