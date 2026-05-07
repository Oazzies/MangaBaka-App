import 'package:flutter/material.dart';

import 'package:bakahyou/utils/constants/app_constants.dart';

class FullScreenImageScreen extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;
  final String? title;
  final String? note;

  const FullScreenImageScreen({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.title,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryBackground.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: title != null 
            ? Text(title!, style: TextStyle(color: AppConstants.textColor, fontSize: 16, fontWeight: FontWeight.bold)) 
            : null,
        iconTheme: IconThemeData(color: AppConstants.textColor),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: heroTag ?? imageUrl,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: AppConstants.textColor),
                ),
              ),
            ),
          ),
          if (note != null && note!.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppConstants.primaryBackground.withValues(alpha: 0.9),
                      AppConstants.primaryBackground.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Text(
                    note!,
                    style: TextStyle(color: AppConstants.textColor, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
