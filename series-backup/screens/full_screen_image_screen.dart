import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import 'package:mangabaka_app/core/utils/widget_utils.dart';

class FullScreenImageScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? heroTag;
  final List<String>? titles;
  final List<String?>? notes;

  const FullScreenImageScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTag,
    this.titles,
    this.notes,
  });

  @override
  State<FullScreenImageScreen> createState() => _FullScreenImageScreenState();
}

class _FullScreenImageScreenState extends State<FullScreenImageScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;
  final List<TransformationController> _transformationControllers = [];

  bool _isZoomed = false;
  TapDownDetails? _doubleTapDetails;

  bool get _isMacOS => !kIsWeb && Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    for (int i = 0; i < widget.imageUrls.length; i++) {
      final controller = TransformationController();
      if (i == widget.initialIndex) {
        controller.addListener(_handleTransformationChanged);
      }
      _transformationControllers.add(controller);
    }
  }

  void _handleTransformationChanged() {
    final scale = _transformationControllers[_currentIndex].value.getMaxScaleOnAxis();
    if (scale > 1.0 != _isZoomed) {
      setState(() {
        _isZoomed = scale > 1.0;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _transformationControllers) {
      controller.removeListener(_handleTransformationChanged);
      controller.dispose();
    }
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < widget.imageUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.titles != null && widget.titles!.length > _currentIndex
        ? widget.titles![_currentIndex]
        : null;
    final note = widget.notes != null && widget.notes!.length > _currentIndex
        ? widget.notes![_currentIndex]
        : null;

    return PopScope(
      canPop: !_isMacOS, // Disable system back gesture on macOS to prevent interference with cover swiping
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: _showControls
            ? AppBar(
                backgroundColor: Colors.black.withValues(alpha: 0.7),
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: title != null
                    ? Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
                actions: [
                  if (widget.imageUrls.length > 1)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.imageUrls.length}',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ),
                ],
              )
            : null,
        body: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            children: [
              ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: PageView.builder(
                  controller: _pageController,
                  physics: _isZoomed
                      ? const NeverScrollableScrollPhysics()
                      : (_isMacOS
                          ? const ClampingScrollPhysics()
                          : const BouncingScrollPhysics()),
                  itemCount: widget.imageUrls.length,
                  onPageChanged: (index) {
                    // Remove listener from old page
                    _transformationControllers[_currentIndex].removeListener(_handleTransformationChanged);
                    
                    setState(() {
                      _currentIndex = index;
                      _isZoomed = false;
                    });
  
                    // Add listener to new page
                    _transformationControllers[index].addListener(_handleTransformationChanged);
  
                    // Reset zoom of other pages
                    for (int i = 0; i < _transformationControllers.length; i++) {
                      if (i != index) {
                        _transformationControllers[i].value = Matrix4.identity();
                      }
                    }
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onDoubleTapDown: (details) => _doubleTapDetails = details,
                      onDoubleTap: () {
                        final controller = _transformationControllers[index];
                        if (controller.value != Matrix4.identity()) {
                          controller.value = Matrix4.identity();
                        } else {
                          final position = _doubleTapDetails!.localPosition;
                          // Zoom in to 3x at the tapped position
                          controller.value = Matrix4.identity()
                            ..translateByVector3(Vector3(-position.dx * 2, -position.dy * 2, 0.0))
                            ..scaleByVector3(Vector3(3.0, 3.0, 1.0));
                        }
                      },
                      child: InteractiveViewer(
                        transformationController: _transformationControllers[index],
                        minScale: 1.0,
                        maxScale: 5.0,
                        child: Center(
                          child: Hero(
                            tag: index == widget.initialIndex
                                ? (widget.heroTag ?? widget.imageUrls[index])
                                : widget.imageUrls[index],
                            child: WidgetUtils.networkImage(
                              url: widget.imageUrls[index],
                              fit: BoxFit.contain,
                              placeholder: const Center(child: CircularProgressIndicator()),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_showControls && widget.imageUrls.length > 1) ...[
                // Left Arrow
                if (_currentIndex > 0)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                        ),
                        onPressed: _previousPage,
                      ),
                    ),
                  ),
                // Right Arrow
                if (_currentIndex < widget.imageUrls.length - 1)
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                        ),
                        onPressed: _nextPage,
                      ),
                    ),
                  ),
              ],
              if (_showControls && note != null && note.isNotEmpty)
                Positioned(
                  bottom: 60,
                  left: 32,
                  right: 32,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        note,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
