// One-off icon rasterizer — NOT part of the normal test suite (lives outside
// test/ so `flutter test` never picks it up). Run explicitly with:
//   flutter test scripts/generate_icons_test.dart
//
// Renders the hand-drawn SVG brand marks to the PNG sizes Android's launcher
// icon system and native splash screen need, since no SVG rasterizer
// (rsvg-convert/inkscape/ImageMagick) is available on this machine — this
// reuses the Flutter engine we already have via flutter_svg + a widget test.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _render(
  WidgetTester tester, {
  required String asset,
  required String outPath,
  required int px,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: SizedBox(
          width: px.toDouble(),
          height: px.toDouble(),
          child: SvgPicture.asset(asset, width: px.toDouble(), height: px.toDouble()),
        ),
      ),
    ),
  );
  // Let the SVG finish decoding/painting before capture.
  await tester.pump();
  await tester.pump();

  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(outPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    // ignore: avoid_print
    print('wrote $outPath (${px}x$px)');
  });
}

void main() {
  testWidgets('generate launcher + splash icons', (tester) async {
    const legacySizes = {
      'mipmap-mdpi': 48,
      'mipmap-hdpi': 72,
      'mipmap-xhdpi': 96,
      'mipmap-xxhdpi': 144,
      'mipmap-xxxhdpi': 192,
    };
    const foregroundSizes = {
      'mipmap-mdpi': 108,
      'mipmap-hdpi': 162,
      'mipmap-xhdpi': 216,
      'mipmap-xxhdpi': 324,
      'mipmap-xxxhdpi': 432,
    };

    for (final entry in legacySizes.entries) {
      await _render(
        tester,
        asset: 'assets/branding/logo_mark.svg',
        outPath: 'android/app/src/main/res/${entry.key}/ic_launcher.png',
        px: entry.value,
      );
    }

    for (final entry in foregroundSizes.entries) {
      await _render(
        tester,
        asset: 'assets/branding/icon_foreground.svg',
        outPath:
            'android/app/src/main/res/${entry.key}/ic_launcher_foreground.png',
        px: entry.value,
      );
    }

    // Splash-screen mark shown centered on the solid green window background
    // while the Flutter engine warms up — one nodpi asset Android downscales
    // as needed.
    await _render(
      tester,
      asset: 'assets/branding/logo_mark.svg',
      outPath: 'android/app/src/main/res/drawable-nodpi/launch_logo.png',
      px: 320,
    );
  });
}
