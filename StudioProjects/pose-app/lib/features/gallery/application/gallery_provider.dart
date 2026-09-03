import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/gallery_service.dart';
import '../domain/gallery_item.dart';

final galleryServiceProvider = Provider<GalleryService>((ref) => GalleryService());

/// Loads captured photos from disk. A plain [FutureProvider] rather than
/// a StateNotifier: the gallery has no real-time stream to react to (no
/// camera frames, no detector) — it only needs to (re)load on demand,
/// which `ref.invalidate(galleryItemsProvider)` handles cleanly after a
/// capture or delete.
final galleryItemsProvider = FutureProvider<List<GalleryItem>>((ref) async {
  final service = ref.watch(galleryServiceProvider);
  return service.listCaptures();
});
