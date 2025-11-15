/// Large, kid-friendly button widget.
///
/// Provides an accessible button with large touch targets, bold text, and
/// high visibility suitable for children.
library;

import 'package:flutter/material.dart';

/// A large, kid-friendly button with customizable color and text.
///
/// This button is designed to be highly visible and easy to interact with,
/// featuring:
/// - Large minimum size (150x80) for easy tapping
/// - Bold, large text (28px)
/// - Rounded corners for friendly appearance
/// - Customizable background color
/// - Elevation for depth perception
///
/// Example usage:
/// ```dart
/// BigButton(
///   text: 'Start Game',
///   onPressed: () => startGame(),
///   color: Colors.green,
/// )
/// ```
class BigButton extends StatelessWidget {
  /// Creates a big button.
  const BigButton({
    required this.text,
    required this.onPressed,
    this.color,
    this.icon,
    super.key,
  });

  /// The text to display on the button.
  final String text;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Optional background color. If not provided, uses theme primary color.
  final Color? color;

  /// Optional icon to display before the text.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? Theme.of(context).colorScheme.primary;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(150, 80),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 6,
        shadowColor: buttonColor.withValues(alpha: 0.5),
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 32),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Text(
              text,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
    );
  }
}

/// A smaller variant of BigButton for secondary actions.
///
/// Features:
/// - Smaller size (120x60) but still large enough for kids
/// - Slightly smaller text (22px)
/// - Same rounded corners and elevation
///
/// Example usage:
/// ```dart
/// MediumButton(
///   text: 'Back',
///   onPressed: () => goBack(),
/// )
/// ```
class MediumButton extends StatelessWidget {
  /// Creates a medium-sized button.
  const MediumButton({
    required this.text,
    required this.onPressed,
    this.color,
    this.icon,
    super.key,
  });

  /// The text to display on the button.
  final String text;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Optional background color. If not provided, uses theme secondary color.
  final Color? color;

  /// Optional icon to display before the text.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? Theme.of(context).colorScheme.secondary;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(120, 60),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        shadowColor: buttonColor.withValues(alpha: 0.5),
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Text(
              text,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
    );
  }
}

/// An outlined variant of BigButton for less prominent actions.
///
/// Features:
/// - Transparent background with colored border
/// - Same size as BigButton (150x80)
/// - Colored text matching border
/// - Lower visual weight than BigButton
///
/// Example usage:
/// ```dart
/// OutlinedBigButton(
///   text: 'Settings',
///   onPressed: () => openSettings(),
///   color: Colors.blue,
/// )
/// ```
class OutlinedBigButton extends StatelessWidget {
  /// Creates an outlined big button.
  const OutlinedBigButton({
    required this.text,
    required this.onPressed,
    this.color,
    this.icon,
    super.key,
  });

  /// The text to display on the button.
  final String text;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Optional border and text color. If not provided, uses theme primary color.
  final Color? color;

  /// Optional icon to display before the text.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? Theme.of(context).colorScheme.primary;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: buttonColor,
        minimumSize: const Size(150, 80),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide(color: buttonColor, width: 3),
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 32, color: buttonColor),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: buttonColor,
                  ),
                ),
              ],
            )
          : Text(
              text,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: buttonColor,
              ),
              textAlign: TextAlign.center,
            ),
    );
  }
}
