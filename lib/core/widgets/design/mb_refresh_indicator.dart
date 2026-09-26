import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';

const double _kDragContainerExtentPercentage = 0.25;
const double _kDragSizeFactorLimit = 1.5;
const Duration _kIndicatorScaleDuration = Duration(milliseconds: 200);

enum _MbRefreshStatus {
  drag,
  armed,
  snap,
  refresh,
  done,
  canceled,
}

/// A refresh indicator that displays MangaBaka's custom [MbSpinner] instead
/// of the standard Material [RefreshProgressIndicator].
class MbRefreshIndicator extends StatefulWidget {
  final Widget child;
  final RefreshCallback onRefresh;
  final double displacement;
  final double edgeOffset;
  final Color? color;
  final Color? backgroundColor;
  final ScrollNotificationPredicate notificationPredicate;

  const MbRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.color,
    this.backgroundColor,
    this.notificationPredicate = defaultScrollNotificationPredicate,
  });

  @override
  State<MbRefreshIndicator> createState() => MbRefreshIndicatorState();
}

class MbRefreshIndicatorState extends State<MbRefreshIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _positionController;
  late final Animation<double> _positionFactor;
  late final Animation<double> _value;

  late final AnimationController _scaleController;
  late final Animation<double> _scaleFactor;

  _MbRefreshStatus? _status;
  double? _dragOffset;
  bool? _isIndicatorAtTop;

  @override
  void initState() {
    super.initState();
    _positionController = AnimationController(vsync: this);
    _positionFactor = _positionController.drive(
      Tween<double>(begin: 0.0, end: _kDragSizeFactorLimit),
    );
    _value = _positionController.drive(
      Tween<double>(begin: 0.0, end: 0.75),
    );

    _scaleController = AnimationController(vsync: this);
    _scaleFactor = _scaleController.drive(
      Tween<double>(begin: 1.0, end: 0.0),
    );
  }

  @override
  void dispose() {
    _positionController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  bool _shouldStart(ScrollNotification notification) {
    return ((notification is ScrollStartNotification &&
                notification.dragDetails != null) ||
            (notification is ScrollUpdateNotification &&
                notification.dragDetails != null)) &&
        ((notification.metrics.axisDirection == AxisDirection.up &&
                notification.metrics.extentAfter == 0.0) ||
            (notification.metrics.axisDirection == AxisDirection.down &&
                notification.metrics.extentBefore == 0.0)) &&
        _status == null &&
        _start(notification.metrics.axisDirection);
  }

  bool _start(AxisDirection direction) {
    if (direction != AxisDirection.down && direction != AxisDirection.up) {
      return false;
    }
    _isIndicatorAtTop = true;
    _dragOffset = 0.0;
    _scaleController.value = 0.0;
    _positionController.value = 0.0;
    return true;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification)) {
      return false;
    }
    if (_shouldStart(notification)) {
      setState(() {
        _status = _MbRefreshStatus.drag;
      });
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      if (_status == _MbRefreshStatus.drag ||
          _status == _MbRefreshStatus.armed) {
        if (notification.metrics.axisDirection == AxisDirection.down) {
          _dragOffset = _dragOffset! - (notification.scrollDelta ?? 0.0);
        } else if (notification.metrics.axisDirection == AxisDirection.up) {
          _dragOffset = _dragOffset! + (notification.scrollDelta ?? 0.0);
        }
        _checkDragOffset(notification.metrics.viewportDimension);
      }
      if (_status == _MbRefreshStatus.armed &&
          notification.dragDetails == null) {
        _show();
      }
    } else if (notification is OverscrollNotification) {
      if (_status == _MbRefreshStatus.drag ||
          _status == _MbRefreshStatus.armed) {
        if (notification.metrics.axisDirection == AxisDirection.down) {
          _dragOffset = _dragOffset! - notification.overscroll;
        } else if (notification.metrics.axisDirection == AxisDirection.up) {
          _dragOffset = _dragOffset! + notification.overscroll;
        }
        _checkDragOffset(notification.metrics.viewportDimension);
      }
    } else if (notification is ScrollEndNotification) {
      switch (_status) {
        case _MbRefreshStatus.armed:
          if (_positionController.value < 1.0) {
            _dismiss(_MbRefreshStatus.canceled);
          } else {
            _show();
          }
        case _MbRefreshStatus.drag:
          _dismiss(_MbRefreshStatus.canceled);
        case _MbRefreshStatus.canceled:
        case _MbRefreshStatus.done:
        case _MbRefreshStatus.refresh:
        case _MbRefreshStatus.snap:
        case null:
          break;
      }
    }
    return false;
  }

  void _checkDragOffset(double containerExtent) {
    if (_dragOffset == null) return;
    double newValue =
        _dragOffset! / (containerExtent * _kDragContainerExtentPercentage);
    if (_status == _MbRefreshStatus.armed) {
      newValue = math.max(newValue, 1.0 / _kDragSizeFactorLimit);
    }
    _positionController.value = clampDouble(newValue, 0.0, 1.0);
    if (_status == _MbRefreshStatus.drag && _positionController.value >= 1.0) {
      _status = _MbRefreshStatus.armed;
    }
  }

  Future<void> _show() async {
    assert(_status == _MbRefreshStatus.armed || _status == null);
    _status = _MbRefreshStatus.snap;
    await _positionController.animateTo(
      1.0 / _kDragSizeFactorLimit,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
    if (mounted) {
      setState(() {
        _status = _MbRefreshStatus.refresh;
      });
    }

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _dismiss(_MbRefreshStatus.done);
      }
    }
  }

  Future<void> _dismiss(_MbRefreshStatus newMode) async {
    if (!mounted) return;
    setState(() {
      _status = newMode;
    });

    switch (_status!) {
      case _MbRefreshStatus.done:
        await _scaleController.animateTo(
          1.0,
          duration: _kIndicatorScaleDuration,
        );
      case _MbRefreshStatus.canceled:
        await _positionController.animateTo(
          0.0,
          duration: _kIndicatorScaleDuration,
        );
      default:
        break;
    }

    if (mounted && _status == newMode) {
      setState(() {
        _dragOffset = null;
        _isIndicatorAtTop = null;
        _status = null;
      });
    }
  }

  /// Programmatically trigger the refresh indicator.
  Future<void> show({bool atTop = true}) async {
    if (_status != _MbRefreshStatus.refresh &&
        _status != _MbRefreshStatus.snap) {
      if (_status == null) {
        _start(atTop ? AxisDirection.down : AxisDirection.up);
      }
      await _show();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showIndeterminate =
        _status == _MbRefreshStatus.refresh || _status == _MbRefreshStatus.done;

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: widget.child,
        ),
        if (_status != null)
          Positioned(
            top: _isIndicatorAtTop == true ? widget.edgeOffset : null,
            bottom: _isIndicatorAtTop == false ? widget.edgeOffset : null,
            left: 0.0,
            right: 0.0,
            child: SizeTransition(
              alignment: Alignment(0.0, _isIndicatorAtTop == true ? 1.0 : -1.0),
              sizeFactor: _positionFactor,
              child: Padding(
                padding: _isIndicatorAtTop == true
                    ? EdgeInsets.only(top: widget.displacement)
                    : EdgeInsets.only(bottom: widget.displacement),
                child: Align(
                  alignment: _isIndicatorAtTop == true
                      ? Alignment.topCenter
                      : Alignment.bottomCenter,
                  child: ScaleTransition(
                    scale: _scaleFactor,
                    child: AnimatedBuilder(
                      animation: _positionController,
                      builder: (context, _) {
                        return Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: widget.backgroundColor ??
                                context.colors.surfaceRaised,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.colors.border,
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.colors.shadow,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: MbSpinner(
                            size: 22,
                            strokeWidth: 2.3,
                            color: widget.color ?? context.colors.accent,
                            value:
                                showIndeterminate ? null : _value.value,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
