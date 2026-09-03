/// A single captured photo on disk. Deliberately holds only a file path
/// and a timestamp — no in-memory image bytes, no thumbnails cached in
/// the model. The gallery grid loads thumbnails lazily via Flutter's own
/// `Image.file`, which handles decoding/caching itself.
class GalleryItem {
  final String path;
  final DateTime capturedAt;

  const GalleryItem({required this.path, required this.capturedAt});
}
