// Shares the receipt card as a PNG image through the platform share sheet.
// Uses RepaintBoundary capture plus share_plus file sharing. Only aggregates
// travel: no letter text, no free-text notes, no names.
//
// See: https://pub.dev/packages/share_plus#share-files

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captures [boundaryKey] as PNG, writes it to the temp directory, and
/// opens the platform share sheet. Returns null on success or a UI-safe
/// error message on failure.
Future<String?> shareReceiptCard({
  required BuildContext context,
  required GlobalKey boundaryKey,
  required String shareText,
  required String fileName,
}) async {
  // Capture the share anchor synchronously: context must not be used
  // across the awaits below.
  final RenderBox? box = context.findRenderObject() as RenderBox?;
  final Rect? origin = box == null
      ? null
      : box.localToGlobal(Offset.zero) & box.size;
  try {
    final RenderRepaintBoundary? boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      return 'Could not capture the receipt. Try again.';
    }
    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (data == null) {
      return 'Could not capture the receipt. Try again.';
    }
    final Directory directory = await getTemporaryDirectory();
    final File file = File('${directory.path}/$fileName');
    await file.writeAsBytes(data.buffer.asUint8List());
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path)],
        fileNameOverrides: <String>[fileName],
        text: shareText,
        sharePositionOrigin: origin,
      ),
    );
    return null;
  } catch (_) {
    return 'Sharing failed. Try again.';
  }
}
