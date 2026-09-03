import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/gallery_provider.dart';
import '../../domain/gallery_item.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(galleryItemsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Your Photos'),
        // A generic AppBar with just a title reads as a template
        // default; a live count grounds it in the actual gallery state
        // without adding a whole subtitle row.
        actions: [
          itemsAsync.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    child: Center(
                      child: Text(
                        '${items.length}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (error, _) => _ErrorState(
          onRetry: () => ref.invalidate(galleryItemsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyState();
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.sm),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.xs,
              mainAxisSpacing: AppSpacing.xs,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _GalleryTile(item: item);
            },
          );
        },
      ),
    );
  }
}

class _GalleryTile extends ConsumerWidget {
  const _GalleryTile({required this.item});

  final GalleryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _PhotoViewer(item: item)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Image.file(
          File(item.path),
          fit: BoxFit.cover,
          // Decode at a bounded resolution instead of the full capture
          // resolution — this tile only ever renders a few centimeters
          // across. Without this, a gallery of many full-resolution
          // photos would decode every visible thumbnail at full size,
          // which is real, avoidable memory pressure (spec Phase 7:
          // "large galleries do not load everything into memory at
          // once" — this is the other half of that, since GridView's
          // own lazy building only bounds *how many* tiles are built,
          // not how large each decoded image is).
          cacheWidth: 300,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.surface,
            child: const Icon(Icons.broken_image_outlined,
                color: AppColors.textDisabled),
          ),
        ),
      ),
    );
  }
}

class _PhotoViewer extends ConsumerWidget {
  const _PhotoViewer({required this.item});

  final GalleryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            File(item.path),
            errorBuilder: (context, error, stackTrace) => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined,
                      size: 40, color: AppColors.textDisabled),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'This photo could no longer be found.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceRaised,
        title: const Text('Delete photo?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(galleryServiceProvider).delete(item.path);
    ref.invalidate(galleryItemsProvider);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_camera_back_outlined,
                size: 40, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No photos yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Photos you capture will show up here.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            const Text('Could not load your photos.'),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
