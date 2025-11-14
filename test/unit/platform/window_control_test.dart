import 'dart:ui' show Size;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_playground/platform/window_control.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WindowControl', () {
    const methodChannel =
        MethodChannel('com.keyboardplayground/window_control');

    setUp(() {
      // Reset any handlers before each test
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    tearDown(() {
      // Clean up handlers after each test
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    group('enterFullscreen', () {
      test('returns true when platform returns true', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'enterFullscreen') {
            return true;
          }
          return null;
        });

        final result = await WindowControl.enterFullscreen();
        expect(result, true);
      });

      test('returns false when platform returns false', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'enterFullscreen') {
            return false;
          }
          return null;
        });

        final result = await WindowControl.enterFullscreen();
        expect(result, false);
      });

      test('returns false when platform returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'enterFullscreen') {
            return null;
          }
          return null;
        });

        final result = await WindowControl.enterFullscreen();
        expect(result, false);
      });

      test('returns false when platform channel throws PlatformException',
          () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'enterFullscreen') {
            throw PlatformException(
              code: 'UNAVAILABLE',
              message: 'Platform not implemented',
            );
          }
          return null;
        });

        final result = await WindowControl.enterFullscreen();
        expect(result, false);
      });

      test('returns false when platform channel throws other exception',
          () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'enterFullscreen') {
            throw Exception('Unexpected error');
          }
          return null;
        });

        final result = await WindowControl.enterFullscreen();
        expect(result, false);
      });

      test('returns false when no handler is registered', () async {
        // No mock handler registered - simulates missing platform implementation
        final result = await WindowControl.enterFullscreen();
        expect(result, false);
      });
    });

    group('exitFullscreen', () {
      test('returns true when platform returns true', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'exitFullscreen') {
            return true;
          }
          return null;
        });

        final result = await WindowControl.exitFullscreen();
        expect(result, true);
      });

      test('returns false when platform returns false', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'exitFullscreen') {
            return false;
          }
          return null;
        });

        final result = await WindowControl.exitFullscreen();
        expect(result, false);
      });

      test('returns false when platform returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'exitFullscreen') {
            return null;
          }
          return null;
        });

        final result = await WindowControl.exitFullscreen();
        expect(result, false);
      });

      test('returns false when platform channel throws PlatformException',
          () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'exitFullscreen') {
            throw PlatformException(
              code: 'UNAVAILABLE',
              message: 'Platform not implemented',
            );
          }
          return null;
        });

        final result = await WindowControl.exitFullscreen();
        expect(result, false);
      });

      test('returns false when no handler is registered', () async {
        final result = await WindowControl.exitFullscreen();
        expect(result, false);
      });
    });

    group('getScreenSize', () {
      test('returns screen size when platform returns valid dimensions',
          () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'getScreenSize') {
            return <String, double>{
              'width': 2560.0,
              'height': 1440.0,
            };
          }
          return null;
        });

        final result = await WindowControl.getScreenSize();
        expect(result, const Size(2560.0, 1440.0));
      });

      test('returns default size when platform returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'getScreenSize') {
            return null;
          }
          return null;
        });

        final result = await WindowControl.getScreenSize();
        expect(result, const Size(1920, 1080));
      });

      test('returns default size when platform returns incomplete data',
          () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'getScreenSize') {
            return <String, double>{'width': 2560.0}; // Missing height
          }
          return null;
        });

        final result = await WindowControl.getScreenSize();
        expect(result, const Size(1920, 1080));
      });

      test('returns default size when platform returns invalid data', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'getScreenSize') {
            return <String, String>{
              'width': 'invalid',
              'height': 'invalid',
            };
          }
          return null;
        });

        final result = await WindowControl.getScreenSize();
        expect(result, const Size(1920, 1080));
      });

      test(
          'returns default size when platform channel throws PlatformException',
          () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'getScreenSize') {
            throw PlatformException(
              code: 'UNAVAILABLE',
              message: 'Platform not implemented',
            );
          }
          return null;
        });

        final result = await WindowControl.getScreenSize();
        expect(result, const Size(1920, 1080));
      });

      test('returns default size when platform channel throws other exception',
          () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'getScreenSize') {
            throw Exception('Unexpected error');
          }
          return null;
        });

        final result = await WindowControl.getScreenSize();
        expect(result, const Size(1920, 1080));
      });

      test('returns default size when no handler is registered', () async {
        final result = await WindowControl.getScreenSize();
        expect(result, const Size(1920, 1080));
      });

      test('handles various screen dimensions correctly', () async {
        final testCases = <Map<String, double>>[
          {'width': 1920.0, 'height': 1080.0}, // Full HD
          {'width': 2560.0, 'height': 1440.0}, // 2K
          {'width': 3840.0, 'height': 2160.0}, // 4K
          {'width': 1366.0, 'height': 768.0}, // Common laptop
          {'width': 1024.0, 'height': 768.0}, // Old 4:3
        ];

        for (final testCase in testCases) {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(methodChannel,
                  (MethodCall methodCall) async {
            if (methodCall.method == 'getScreenSize') {
              return testCase;
            }
            return null;
          });

          final result = await WindowControl.getScreenSize();
          expect(
            result,
            Size(testCase['width']!, testCase['height']!),
            reason: 'Failed for ${testCase['width']}x${testCase['height']}',
          );
        }
      });
    });

    group('isFullscreen', () {
      test('returns true when platform returns true', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'isFullscreen') {
            return true;
          }
          return null;
        });

        final result = await WindowControl.isFullscreen();
        expect(result, true);
      });

      test('returns false when platform returns false', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'isFullscreen') {
            return false;
          }
          return null;
        });

        final result = await WindowControl.isFullscreen();
        expect(result, false);
      });

      test('returns false when platform returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'isFullscreen') {
            return null;
          }
          return null;
        });

        final result = await WindowControl.isFullscreen();
        expect(result, false);
      });

      test('returns false when platform channel throws PlatformException',
          () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          if (methodCall.method == 'isFullscreen') {
            throw PlatformException(
              code: 'UNAVAILABLE',
              message: 'Platform not implemented',
            );
          }
          return null;
        });

        final result = await WindowControl.isFullscreen();
        expect(result, false);
      });

      test('returns false when no handler is registered', () async {
        final result = await WindowControl.isFullscreen();
        expect(result, false);
      });
    });

    group('Integration scenarios', () {
      test('fullscreen toggle workflow', () async {
        var isFullscreenState = false;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'isFullscreen':
              return isFullscreenState;
            case 'enterFullscreen':
              isFullscreenState = true;
              return true;
            case 'exitFullscreen':
              isFullscreenState = false;
              return true;
            default:
              return null;
          }
        });

        // Initially not fullscreen
        expect(await WindowControl.isFullscreen(), false);

        // Enter fullscreen
        expect(await WindowControl.enterFullscreen(), true);
        expect(await WindowControl.isFullscreen(), true);

        // Exit fullscreen
        expect(await WindowControl.exitFullscreen(), true);
        expect(await WindowControl.isFullscreen(), false);
      });

      test('handles screen size query during fullscreen', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel,
                (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getScreenSize':
              return <String, double>{
                'width': 3840.0,
                'height': 2160.0,
              };
            case 'enterFullscreen':
              return true;
            case 'isFullscreen':
              return true;
            default:
              return null;
          }
        });

        final size = await WindowControl.getScreenSize();
        expect(size, const Size(3840.0, 2160.0));

        final enterResult = await WindowControl.enterFullscreen();
        expect(enterResult, true);

        final fullscreenResult = await WindowControl.isFullscreen();
        expect(fullscreenResult, true);
      });
    });
  });
}
