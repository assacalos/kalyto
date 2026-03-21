import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/media_model.dart';
import 'package:easyconnect/providers/media_state.dart';
import 'package:easyconnect/services/media_service.dart';
import 'package:easyconnect/services/camera_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easyconnect/utils/logger.dart';

final mediaProvider =
    NotifierProvider<MediaNotifier, MediaState>(MediaNotifier.new);

class MediaNotifier extends Notifier<MediaState> {
  final MediaService _mediaService = MediaService();
  final CameraService _cameraService = CameraService();

  @override
  MediaState build() => MediaState();

  Future<void> loadMedia({bool forceRefresh = false}) async {
    if (!forceRefresh && state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final media = await _mediaService.getAllMedia();
      final List<MediaItem> allMedia = [
        ...media['attendance'] ?? <MediaItem>[],
        ...media['bon_commande'] ?? <MediaItem>[],
        ...media['expense'] ?? <MediaItem>[],
        ...media['salary'] ?? <MediaItem>[],
        ...media['other'] ?? <MediaItem>[],
      ];
      state = state.copyWith(
        mediaByCategory: media,
        allMedia: allMedia,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error(
        'Erreur lors du chargement des médias: $e',
        tag: 'MEDIA_NOTIFIER',
      );
      state = state.copyWith(isLoading: false);
    }
  }

  List<MediaItem> getFilteredMedia() {
    if (state.selectedCategory == 'all') return state.allMedia;
    return state.mediaByCategory[state.selectedCategory] ?? [];
  }

  int getMediaCount(String category) {
    return state.mediaByCategory[category]?.length ?? 0;
  }

  void filterByCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  Future<void> scanDocument(BuildContext context) async {
    try {
      final selectionType = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Scanner un document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Sélectionner depuis la galerie'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Sélectionner un fichier'),
                onTap: () => Navigator.pop(ctx, 'file'),
              ),
            ],
          ),
        ),
      );

      if (selectionType == null) return;

      File? selectedFile;

      if (selectionType == 'camera') {
        selectedFile = await _cameraService.takePicture();
      } else if (selectionType == 'gallery') {
        selectedFile = await _cameraService.pickImageFromGallery();
      } else if (selectionType == 'file') {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
        if (result != null && result.files.single.path != null) {
          selectedFile = File(result.files.single.path!);
        }
      }

      if (selectedFile != null && context.mounted) {
        await _showCategorySelectionDialog(context, selectedFile);
      }
    } catch (e) {
      AppLogger.error('Erreur lors du scan: $e', tag: 'MEDIA_NOTIFIER');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Impossible de scanner le document: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _showCategorySelectionDialog(
      BuildContext context, File file) async {
    final category = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choisir une catégorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.blue),
              title: const Text('Pointage'),
              onTap: () => Navigator.pop(ctx, 'attendance'),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.orange),
              title: const Text('Bon de commande'),
              onTap: () => Navigator.pop(ctx, 'bon_commande'),
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: Colors.green),
              title: const Text('Dépense'),
              onTap: () => Navigator.pop(ctx, 'expense'),
            ),
            ListTile(
              leading: const Icon(
                Icons.account_balance_wallet,
                color: Colors.purple,
              ),
              title: const Text('Salaire'),
              onTap: () => Navigator.pop(ctx, 'salary'),
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.grey),
              title: const Text('Autre'),
              onTap: () => Navigator.pop(ctx, 'other'),
            ),
          ],
        ),
      ),
    );

    if (category != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Fonctionnalité d\'upload à implémenter pour la catégorie: $category'),
        ),
      );
    }
  }
}
