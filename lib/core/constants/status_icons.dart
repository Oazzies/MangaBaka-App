import 'package:flutter/material.dart';

/// Material equivalents of the icons mangabaka.org uses for statuses.
class StatusIcons {
  StatusIcons._();

  /// Library state (site: book-check, circle-dashed, trash, pause, book,
  /// book-open-text, rotate-ccw).
  static IconData forState(String state) => switch (state) {
    'reading' => Icons.auto_stories_outlined,
    'rereading' => Icons.rotate_left,
    'completed' => Icons.fact_check_outlined,
    'paused' => Icons.pause,
    'dropped' => Icons.delete_outline,
    'plan_to_read' => Icons.book_outlined,
    'considering' => Icons.radio_button_unchecked,
    _ => Icons.help_outline,
  };

  /// Series publication status (site: play, circle-check-big, circle-pause,
  /// trash, circle-dot-dashed, circle-help).
  static IconData forSeriesStatus(String status) =>
      switch (status.toLowerCase()) {
        'releasing' || 'ongoing' => Icons.play_arrow_outlined,
        'completed' => Icons.check_circle_outline,
        'hiatus' => Icons.pause_circle_outline,
        'cancelled' || 'canceled' => Icons.delete_outline,
        'upcoming' => Icons.adjust,
        _ => Icons.help_outline,
      };
}
