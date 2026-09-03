import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/gallery_item.dart';

const String kCaptureFilePrefix = 'avd_';
const String kCaptureFileSuffix = '.jpg';

/// Recovers a capture's timestamp from its filename
/// (`avd_<millisecondsSinceEpoch>.jpg`, set by `CameraService.capturePhoto()`).
/// Pulled out as a standalone pure function so it's unit-testable without
/// touching the filesystem or `path_provider`'s platform channel — see
/// test/gallery_service_test.dart.
DateTime? parseCaptureTimestamp(String fileName) {
  if (!fileName.startsWith(kCaptureFilePrefix) ||
      !fileName.endsWith(kCaptureFileSuffix)) {
    return null;
  }
  final withoutPrefix = fileName.substring(kCaptureFilePrefix.length);
  final withoutSuffix = withoutPrefix.substring(
    0,
    withoutPrefix.length - kCaptureFileSuffix.length,
  );
  final millis = int.tryParse(withoutSuffix);
  if (millis == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(millis);
}

/// Reads/deletes captured photos from the app's documents directory —
/// the same location `CameraService.capturePhoto()` already saves to
/// (see camera/data/camera_service.dart). No new storage location is
/// introduced; this feature only adds a way to browse what's already
/// being written.
class GalleryService {
  Future<List<GalleryItem>> listCaptures() async {
    final dir = await getApplicationDocumentsDirectory();
    if (!await dir.exists()) return const [];

    final entries = await dir.list().toList();
    final items = <GalleryItem>[];

    for (final entry in entries) {
      if (entry is! File) continue;
      final name = entry.uri.pathSegments.last;
      final parsedTimestamp = parseCaptureTimestamp(name);
      if (parsedTimestamp == null) continue; // not one of ours
      items.add(GalleryItem(path: entry.path, capturedAt: parsedTimestamp));
    }

    items.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return items;
  }

  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
