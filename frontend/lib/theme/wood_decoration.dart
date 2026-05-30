import 'package:flutter/material.dart';

/// Reusable wood-texture decorations for cards, app bars, and nav pills.
///
/// Uses the generated `assets/images/textures/wood_texture.png` asset
/// as a background image with optional neumorphic shadows.
class WoodDecoration {
  const WoodDecoration._();

  static const String _texturePath = 'assets/images/textures/wood_texture.png';

  /// Raised wood plate with texture, border, and directional shadows.
  static BoxDecoration plate({
    double radius = 16,
    double depth = 1.0,
  }) {
    return BoxDecoration(
      image: const DecorationImage(
        image: AssetImage(_texturePath),
        fit: BoxFit.cover,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: const Color(0xFFC19A6B).withValues(alpha: 0.6),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF6B3E1F).withValues(alpha: 0.45 * depth),
          offset: Offset(0, 4 * depth),
          blurRadius: 10 * depth,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: const Color(0xFFC19A6B).withValues(alpha: 0.25 * depth),
          offset: Offset(0, -2 * depth),
          blurRadius: 4 * depth,
          spreadRadius: -1,
        ),
      ],
    );
  }

  /// Inset wood plate for pressed/depressed states.
  static BoxDecoration inset({
    double radius = 16,
    double depth = 1.0,
  }) {
    return BoxDecoration(
      image: const DecorationImage(
        image: AssetImage(_texturePath),
        fit: BoxFit.cover,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: const Color(0xFF6B3E1F).withValues(alpha: 0.4),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF6B3E1F).withValues(alpha: 0.3 * depth),
          offset: Offset(0, 3 * depth),
          blurRadius: 6 * depth,
          spreadRadius: -1,
        ),
      ],
    );
  }

  /// Background widget for AppBar flexibleSpace.
  static Widget appBarBackground() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(_texturePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Background widget for SliverAppBar flexibleSpace.
  static Widget sliverAppBarBackground({
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
  }) {
    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage(_texturePath),
          fit: BoxFit.cover,
        ),
        borderRadius: borderRadius,
        boxShadow: shadows,
      ),
    );
  }

  /// Circular wood texture for emblem plates and avatars.
  static BoxDecoration circle({double depth = 1.0}) {
    return BoxDecoration(
      shape: BoxShape.circle,
      image: const DecorationImage(
        image: AssetImage(_texturePath),
        fit: BoxFit.cover,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF6B3E1F).withValues(alpha: 0.45 * depth),
          offset: Offset(0, 4 * depth),
          blurRadius: 10 * depth,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: const Color(0xFFC19A6B).withValues(alpha: 0.25 * depth),
          offset: Offset(0, -2 * depth),
          blurRadius: 4 * depth,
          spreadRadius: -1,
        ),
      ],
    );
  }
}
