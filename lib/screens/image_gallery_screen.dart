import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../utils/constants.dart';

/// Full-screen, pinch-to-zoom viewer for a disease's reference photos.
/// Reached by tapping any thumbnail in the disease list or detail screen —
/// this is where a farmer gets a close, confident look before deciding
/// "yes, that's what my crop looks like."
class ImageGalleryScreen extends StatefulWidget {
  final String title;
  final List<String> imagePaths;
  final int initialIndex;

  const ImageGalleryScreen({
    super.key,
    required this.title,
    required this.imagePaths,
    this.initialIndex = 0,
  });

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_index + 1} / ${widget.imagePaths.length}',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _controller,
            itemCount: widget.imagePaths.length,
            onPageChanged: (i) => setState(() => _index = i),
            builder: (context, i) => PhotoViewGalleryPageOptions(
              imageProvider: AssetImage(widget.imagePaths[i]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 4,
              errorBuilder: (_, __, ___) => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_not_supported,
                        size: 56, color: Colors.white38),
                    SizedBox(height: 12),
                    Text('Reference image not yet added',
                        style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: kAccentGreen),
            ),
          ),
          if (widget.imagePaths.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imagePaths.length,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _index == i ? Colors.white : Colors.white30,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
