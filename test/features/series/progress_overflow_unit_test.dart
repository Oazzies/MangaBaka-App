import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/features/series/widgets/progress_overflow_dialog.dart';

void main() {
  group('evaluateProgressOverflow', () {
    test('allows any value when total is null, zero, or negative', () {
      for (final mode in ProgressOverflowMode.values) {
        expect(
          evaluateProgressOverflow(mode: mode, newValue: 10, total: null),
          ProgressOverflowDecision.allowed,
        );
        expect(
          evaluateProgressOverflow(mode: mode, newValue: 10, total: 0),
          ProgressOverflowDecision.allowed,
        );
        expect(
          evaluateProgressOverflow(mode: mode, newValue: 10, total: -5),
          ProgressOverflowDecision.allowed,
        );
      }
    });

    test('allows values at or below total in all modes', () {
      for (final mode in ProgressOverflowMode.values) {
        expect(
          evaluateProgressOverflow(
            mode: mode,
            newValue: 100,
            total: 100,
            seriesStatus: 'completed',
          ),
          ProgressOverflowDecision.allowed,
        );
        expect(
          evaluateProgressOverflow(
            mode: mode,
            newValue: 50,
            total: 100,
            seriesStatus: 'completed',
          ),
          ProgressOverflowDecision.allowed,
        );
      }
    });

    test('never blocks overflow regardless of series status', () {
      expect(
        evaluateProgressOverflow(
          mode: ProgressOverflowMode.never,
          newValue: 101,
          total: 100,
          seriesStatus: 'releasing',
        ),
        ProgressOverflowDecision.blocked,
      );
      expect(
        evaluateProgressOverflow(
          mode: ProgressOverflowMode.never,
          newValue: 101,
          total: 100,
          seriesStatus: 'completed',
        ),
        ProgressOverflowDecision.blocked,
      );
    });

    test('prompt asks on overflow regardless of series status', () {
      expect(
        evaluateProgressOverflow(
          mode: ProgressOverflowMode.prompt,
          newValue: 101,
          total: 100,
          seriesStatus: 'releasing',
        ),
        ProgressOverflowDecision.prompt,
      );
      expect(
        evaluateProgressOverflow(
          mode: ProgressOverflowMode.prompt,
          newValue: 101,
          total: 100,
          seriesStatus: 'completed',
        ),
        ProgressOverflowDecision.prompt,
      );
    });

    test('always allows overflow regardless of series status', () {
      expect(
        evaluateProgressOverflow(
          mode: ProgressOverflowMode.always,
          newValue: 101,
          total: 100,
          seriesStatus: 'completed',
        ),
        ProgressOverflowDecision.allowed,
      );
    });

    test('promptCompletedOnly prompts only when series status is completed', () {
      expect(
        evaluateProgressOverflow(
          mode: ProgressOverflowMode.promptCompletedOnly,
          newValue: 101,
          total: 100,
          seriesStatus: 'completed',
        ),
        ProgressOverflowDecision.prompt,
      );
      expect(
        evaluateProgressOverflow(
          mode: ProgressOverflowMode.promptCompletedOnly,
          newValue: 101,
          total: 100,
          seriesStatus: 'Completed',
        ),
        ProgressOverflowDecision.prompt,
      );
      expect(
        evaluateProgressOverflow(
          mode: ProgressOverflowMode.promptCompletedOnly,
          newValue: 101,
          total: 100,
          seriesStatus: 'releasing',
        ),
        ProgressOverflowDecision.allowed,
      );
      expect(
        evaluateProgressOverflow(
          mode: ProgressOverflowMode.promptCompletedOnly,
          newValue: 101,
          total: 100,
          seriesStatus: 'hiatus',
        ),
        ProgressOverflowDecision.allowed,
      );
      expect(
        evaluateProgressOverflow(
          mode: ProgressOverflowMode.promptCompletedOnly,
          newValue: 101,
          total: 100,
          seriesStatus: null,
        ),
        ProgressOverflowDecision.allowed,
      );
    });
  });
}
