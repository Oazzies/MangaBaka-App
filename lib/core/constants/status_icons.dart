import 'package:flutter/material.dart';

/// Material equivalents of the icons mangabaka.org uses for statuses.
class StatusIcons {
  StatusIcons._();

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
