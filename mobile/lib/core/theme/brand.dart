import 'package:flutter/material.dart';

/// Workify's name and colors, in one place.
abstract final class Brand {
  static const name = 'Workify';
  static const tagline = 'Find work that works for you';

  static const green = Color(0xFF5CB135);
  static const darkGreen = Color(0xFF2F7A1F);

  /// The logo's arrow when the logo is white on [green].
  static const paleGreen = Color(0xFFD4F2BC);
}
