/// Performance monitoring utilities for profiling and benchmarking games.
///
/// Provides tools to measure FPS, memory usage, and detect performance issues.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Monitors application performance metrics.
///
/// Tracks FPS, frame timing, and provides performance statistics.
class PerformanceMonitor {
  /// Creates a new performance monitor.
  PerformanceMonitor() {
    _startMonitoring();
  }

  final List<Duration> _frameTimes = [];
  DateTime? _lastFrameTime;
  Timer? _statsTimer;
  bool _disposed = false;

  /// Current FPS (frames per second).
  double get currentFPS => _currentFPS;
  double _currentFPS = 0;

  /// Average frame time in milliseconds.
  double get averageFrameTime => _averageFrameTime;
  double _averageFrameTime = 0;

  /// Maximum frame time in the last second (worst frame).
  double get maxFrameTime => _maxFrameTime;
  double _maxFrameTime = 0;

  /// Number of dropped frames (>16.67ms for 60 FPS).
  int get droppedFrames => _droppedFrames;
  int _droppedFrames = 0;

  /// Starts monitoring frame timing.
  void _startMonitoring() {
    if (_disposed) return;

    // Monitor frame callbacks
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);

    // Update statistics every second
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateStatistics();
    });
  }

  /// Called after each frame is rendered.
  void _onFrame(Duration timestamp) {
    if (_disposed) return;

    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!);
      _frameTimes.add(frameTime);

      // Track dropped frames (assuming 60 FPS target = 16.67ms)
      if (frameTime.inMicroseconds > 16667) {
        _droppedFrames++;
      }
    }
    _lastFrameTime = now;

    // Schedule next frame callback
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  /// Updates performance statistics.
  void _updateStatistics() {
    if (_frameTimes.isEmpty) return;

    // Calculate FPS
    _currentFPS = _frameTimes.length.toDouble();

    // Calculate average frame time
    final totalMicroseconds = _frameTimes.fold<int>(
      0,
      (sum, duration) => sum + duration.inMicroseconds,
    );
    _averageFrameTime = totalMicroseconds / _frameTimes.length / 1000.0;

    // Calculate max frame time
    _maxFrameTime = _frameTimes
        .map((d) => d.inMicroseconds / 1000.0)
        .reduce((a, b) => a > b ? a : b);

    // Clear for next second
    _frameTimes.clear();
    _droppedFrames = 0;
  }

  /// Logs current performance statistics.
  void logStatistics() {
    developer.log(
      'Performance: '
      'FPS=$currentFPS, '
      'AvgFrameTime=${averageFrameTime.toStringAsFixed(2)}ms, '
      'MaxFrameTime=${maxFrameTime.toStringAsFixed(2)}ms, '
      'DroppedFrames=$droppedFrames',
      name: 'PerformanceMonitor',
    );
  }

  /// Disposes the monitor and stops tracking.
  void dispose() {
    _disposed = true;
    _statsTimer?.cancel();
    _statsTimer = null;
    _frameTimes.clear();
  }
}

/// A widget that displays performance overlay information.
///
/// Shows FPS, frame time, and dropped frames in debug mode.
class PerformanceOverlay extends StatefulWidget {
  /// Creates a performance overlay widget.
  const PerformanceOverlay({
    required this.child,
    this.enabled = kDebugMode,
    super.key,
  });

  /// The child widget to wrap.
  final Widget child;

  /// Whether the overlay is enabled (default: debug mode only).
  final bool enabled;

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  PerformanceMonitor? _monitor;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _monitor = PerformanceMonitor();
      _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _monitor?.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _monitor == null) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF000000).withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _monitor!.currentFPS < 55
                    ? const Color(0xFFEF4444) // Red if below 55 FPS
                    : const Color(0xFF10B981), // Green if good
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FPS: ${_monitor!.currentFPS.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _monitor!.currentFPS < 55
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  'Avg: ${_monitor!.averageFrameTime.toStringAsFixed(2)}ms',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFFFFFF),
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  'Max: ${_monitor!.maxFrameTime.toStringAsFixed(2)}ms',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFFFFFF),
                    fontFamily: 'monospace',
                  ),
                ),
                if (_monitor!.droppedFrames > 0)
                  Text(
                    'Dropped: ${_monitor!.droppedFrames}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFEF4444),
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
