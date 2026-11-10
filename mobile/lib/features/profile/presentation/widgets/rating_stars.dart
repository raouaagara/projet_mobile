import 'package:flutter/material.dart';

/// Read-only stars, supports half stars (e.g. 4.5).
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 18});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    const color = Colors.amber;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : rating >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            size: size,
            color: color,
          ),
      ],
    );
  }
}

/// Tappable 1–5 stars.
class RatingInput extends StatelessWidget {
  const RatingInput({super.key, required this.value, required this.onChanged, this.size = 40});

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            iconSize: size,
            tooltip: '$i star${i > 1 ? 's' : ''}',
            onPressed: () => onChanged(i),
            icon: Icon(
              i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              color: Colors.amber,
            ),
          ),
      ],
    );
  }
}
