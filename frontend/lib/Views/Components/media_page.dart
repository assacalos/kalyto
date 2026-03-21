import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/media_model.dart';
import 'package:easyconnect/providers/media_notifier.dart';
import 'package:easyconnect/providers/media_state.dart';
import 'package:easyconnect/Views/Components/dashboard_wrapper.dart';
import 'package:intl/intl.dart';

/// Page pour afficher tous les médias (images et fichiers) par catégorie
class MediaPage extends ConsumerStatefulWidget {
  const MediaPage({super.key});

  @override
  ConsumerState<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends ConsumerState<MediaPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mediaProvider.notifier).loadMedia();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaProvider);
    final notifier = ref.read(mediaProvider.notifier);
    final filteredMedia = notifier.getFilteredMedia();

    return DashboardWrapper(
      currentIndex: 4,
      appBar: AppBar(
        title: const Text('Médias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.scanner),
            tooltip: 'Scanner un document',
            onPressed: () => notifier.scanDocument(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => notifier.scanDocument(context),
        icon: const Icon(Icons.scanner),
        label: const Text('Scanner'),
      ),
      child: Column(
        children: [
          _buildCategoryFilters(context, state, notifier),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredMedia.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun média trouvé',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: filteredMedia.length,
                        itemBuilder: (context, index) {
                          return _buildMediaItem(
                              context, filteredMedia[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(
    BuildContext context,
    MediaState state,
    MediaNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            _buildCategoryChip(
              notifier,
              'all',
              'Tous',
              Icons.photo_library,
              state.allMedia.length,
              state.selectedCategory,
            ),
            _buildCategoryChip(
              notifier,
              'attendance',
              'Pointages',
              Icons.access_time,
              notifier.getMediaCount('attendance'),
              state.selectedCategory,
            ),
            _buildCategoryChip(
              notifier,
              'bon_commande',
              'Bons de commande',
              Icons.shopping_cart,
              notifier.getMediaCount('bon_commande'),
              state.selectedCategory,
            ),
            _buildCategoryChip(
              notifier,
              'expense',
              'Dépenses',
              Icons.receipt,
              notifier.getMediaCount('expense'),
              state.selectedCategory,
            ),
            _buildCategoryChip(
              notifier,
              'salary',
              'Salaires',
              Icons.account_balance_wallet,
              notifier.getMediaCount('salary'),
              state.selectedCategory,
            ),
            _buildCategoryChip(
              notifier,
              'other',
              'Autres',
              Icons.folder,
              notifier.getMediaCount('other'),
              state.selectedCategory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    MediaNotifier notifier,
    String category,
    String label,
    IconData icon,
    int count,
    String selectedCategory,
  ) {
    final isSelected = selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blue : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
        onSelected: (_) => notifier.filterByCategory(category),
      ),
    );
  }

  Widget _buildMediaItem(BuildContext context, MediaItem media) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showMediaDetail(context, media),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: media.isImage
                  ? CachedNetworkImage(
                      imageUrl: media.url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          media.isPdf
                              ? Icons.picture_as_pdf
                              : Icons.insert_drive_file,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.fileName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(media.category),
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getCategoryLabel(media.category),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd/MM/yyyy').format(media.createdAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'attendance':
        return Icons.access_time;
      case 'bon_commande':
        return Icons.shopping_cart;
      case 'expense':
        return Icons.receipt;
      case 'salary':
        return Icons.account_balance_wallet;
      default:
        return Icons.folder;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'attendance':
        return 'Pointage';
      case 'bon_commande':
        return 'Bon de commande';
      case 'expense':
        return 'Dépense';
      case 'salary':
        return 'Salaire';
      default:
        return 'Autre';
    }
  }

  void _showMediaDetail(BuildContext context, MediaItem media) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(media.fileName),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Flexible(
              child: media.isImage
                  ? CachedNetworkImage(
                      imageUrl: media.url,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.broken_image, size: 64),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            media.isPdf
                                ? Icons.picture_as_pdf
                                : Icons.insert_drive_file,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            media.fileName,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.download),
                            label: const Text('Télécharger'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Téléchargement à implémenter'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Catégorie', _getCategoryLabel(media.category)),
                  _buildInfoRow(
                    'Date',
                    DateFormat('dd/MM/yyyy à HH:mm').format(media.createdAt),
                  ),
                  if (media.fileSize != null)
                    _buildInfoRow(
                        'Taille', _formatFileSize(media.fileSize!)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
