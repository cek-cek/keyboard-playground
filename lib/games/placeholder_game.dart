/// Placeholder game that displays input events for testing integration.
///
/// This game shows all keyboard and mouse events in real-time, which is
/// useful for verifying that the input capture and event routing system
/// is working correctly. This will be used until actual games are
/// implemented in PRD-009+.
library;

import 'package:flutter/material.dart';
import 'package:keyboard_playground/games/base_game.dart';
import 'package:keyboard_playground/platform/input_events.dart' as events;

/// A simple game that displays all input events for testing.
///
/// This game shows:
/// - Keyboard events with key names and modifiers
/// - Mouse movement with coordinates
/// - Mouse button clicks with coordinates
/// - Mouse scroll events with deltas
///
/// Events are displayed in a scrollable list with the most recent at the top.
class PlaceholderGame extends BaseGame {
  /// Creates a new placeholder game.
  PlaceholderGame() {
    _recentEvents.addAll([
      'Welcome to Keyboard Playground!',
      'Press any key or move the mouse to see events...',
      '',
      'Exit sequence: Alt + Ctrl + Right Arrow + Esc + Q',
    ]);
    _eventsNotifier.value = List.from(_recentEvents);
  }

  final List<String> _recentEvents = [];
  final ValueNotifier<List<String>> _eventsNotifier =
      ValueNotifier<List<String>>([]);

  @override
  String get id => 'placeholder';

  @override
  String get name => 'Input Display';

  @override
  String get description => 'Shows keyboard and mouse events in real-time';

  @override
  Widget buildUI() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Slate 900
            Color(0xFF1E293B), // Slate 800
          ],
        ),
      ),
      child: Center(
        child: ValueListenableBuilder<List<String>>(
          valueListenable: _eventsNotifier,
          builder: (context, events, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                const Text(
                  'Keyboard Playground',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Input Event Monitor',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 48),

                // Events display box
                Container(
                  width: 800,
                  height: 500,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    border: Border.all(
                      color: const Color(0xFF3B82F6), // Blue 500
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Recent Events',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${events.length} events',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Divider
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF3B82F6).withOpacity(0.1),
                              const Color(0xFF3B82F6).withOpacity(0.5),
                              const Color(0xFF3B82F6).withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Events list
                      Expanded(
                        child: ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            final isWelcome = index >= events.length - 4;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  // Timestamp or bullet
                                  if (!isWelcome)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: _getEventColor(event),
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  else
                                    const SizedBox(width: 20),

                                  // Event text
                                  Expanded(
                                    child: Text(
                                      event,
                                      style: TextStyle(
                                        fontSize: isWelcome ? 14 : 16,
                                        color: isWelcome
                                            ? Colors.white60
                                            : Colors.white,
                                        fontFamily: 'monospace',
                                        fontStyle: isWelcome
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Hint text
                const Text(
                  'All keyboard and mouse events are being captured',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white38,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Gets the color for an event based on its type.
  Color _getEventColor(String event) {
    if (event.startsWith('⌨')) {
      return const Color(0xFF10B981); // Green for keyboard
    } else if (event.startsWith('🖱')) {
      return const Color(0xFF3B82F6); // Blue for mouse
    } else if (event.startsWith('🔽')) {
      return const Color(0xFFF59E0B); // Orange for scroll
    }
    return Colors.white54;
  }

  @override
  void onKeyEvent(events.KeyEvent event) {
    final modifiers = event.modifiers
        .map((m) => m.name.substring(0, 1).toUpperCase() + m.name.substring(1))
        .toList();
    final modStr = modifiers.isEmpty ? '' : '${modifiers.join('+')}+';

    final eventStr = '⌨  ${event.isDown ? "↓" : "↑"}  '
        '$modStr${event.key}  '
        '(code: ${event.keyCode})';

    _addEvent(eventStr);
  }

  @override
  void onMouseEvent(events.InputEvent event) {
    String eventStr;

    if (event is events.MouseMoveEvent) {
      eventStr = '🖱  Move  '
          '(${event.x.toInt()}, ${event.y.toInt()})';
    } else if (event is events.MouseButtonEvent) {
      eventStr = '🖱  ${event.isDown ? "↓" : "↑"}  '
          '${event.button.name.toUpperCase()}  '
          '(${event.x.toInt()}, ${event.y.toInt()})';
    } else if (event is events.MouseScrollEvent) {
      eventStr = '🔽  Scroll  '
          '(Δx: ${event.deltaX.toStringAsFixed(1)}, '
          'Δy: ${event.deltaY.toStringAsFixed(1)})';
    } else {
      return;
    }

    _addEvent(eventStr);
  }

  /// Adds an event to the list and notifies listeners.
  void _addEvent(String eventStr) {
    // Remove welcome messages when first real event arrives
    if (_recentEvents.length == 4 &&
        _recentEvents.last.contains('Exit sequence')) {
      _recentEvents.clear();
    }

    _recentEvents.insert(0, eventStr);

    // Keep only the last 50 events
    if (_recentEvents.length > 50) {
      _recentEvents.removeLast();
    }

    _eventsNotifier.value = List.from(_recentEvents);
  }

  @override
  void dispose() {
    _eventsNotifier.dispose();
    super.dispose();
  }
}
