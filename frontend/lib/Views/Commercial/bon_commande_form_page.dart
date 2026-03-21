import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easyconnect/providers/bon_commande_notifier.dart';
import 'package:easyconnect/providers/bon_commande_state.dart';
import 'package:easyconnect/services/camera_service.dart';
import 'package:easyconnect/Views/Components/client_selection_dialog.dart';

class BonCommandeFormPage extends ConsumerStatefulWidget {
  final bool isEditing;
  final int? bonCommandeId;

  const BonCommandeFormPage({super.key, this.isEditing = false, this.bonCommandeId});

  @override
  ConsumerState<BonCommandeFormPage> createState() => _BonCommandeFormPageState();
}

class _BonCommandeFormPageState extends ConsumerState<BonCommandeFormPage> {
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (!widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(bonCommandeProvider.notifier).clearForm();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bonCommandeProvider);
    final notifier = ref.read(bonCommandeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Modifier le bon de commande' : 'Nouveau bon de commande'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Client', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Text('Validés uniquement', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      state.selectedClient != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.selectedClient!.nomEntreprise?.isNotEmpty == true
                                      ? state.selectedClient!.nomEntreprise!
                                      : '${state.selectedClient!.nom ?? ''} ${state.selectedClient!.prenom ?? ''}'.trim().isNotEmpty
                                          ? '${state.selectedClient!.nom ?? ''} ${state.selectedClient!.prenom ?? ''}'.trim()
                                          : 'Client #${state.selectedClient!.id}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                if (state.selectedClient!.nomEntreprise?.isNotEmpty == true &&
                                    '${state.selectedClient!.nom ?? ''} ${state.selectedClient!.prenom ?? ''}'.trim().isNotEmpty)
                                  Text('Contact: ${state.selectedClient!.nom ?? ''} ${state.selectedClient!.prenom ?? ''}'.trim()),
                                if (state.selectedClient!.email != null) Text(state.selectedClient!.email ?? ''),
                                if (state.selectedClient!.contact != null) Text(state.selectedClient!.contact ?? ''),
                                const SizedBox(height: 8),
                                TextButton(onPressed: notifier.clearSelectedClient, child: const Text('Changer de client')),
                              ],
                            )
                          : ElevatedButton(
                              onPressed: () => _showClientSelection(context, notifier),
                              child: const Text('Sélectionner un client'),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fichiers scannés', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _selectFiles(context, notifier),
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Ajouter des fichiers'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Formats acceptés: PDF, Images, Documents (max 10 MB par fichier)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 16),
                      state.selectedFiles.isEmpty
                          ? const Center(child: Text('Aucun fichier sélectionné'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.selectedFiles.length,
                              itemBuilder: (context, index) => _buildFileCard(state.selectedFiles[index], index, notifier),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSaveButton(context, state, notifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileCard(Map<String, dynamic> file, int index, BonCommandeNotifier notifier) {
    final fileName = file['name'] as String? ?? 'Fichier';
    final filePath = file['path'] as String? ?? '';
    final fileType = file['type'] as String? ?? 'document';
    final fileSize = file['size'] as int? ?? 0;
    IconData fileIcon = fileType == 'pdf' ? Icons.picture_as_pdf : fileType == 'image' ? Icons.image : Icons.insert_drive_file;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(fileIcon, color: Colors.blue),
        title: Text(fileName),
        subtitle: Text(_formatFileSize(fileSize)),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => notifier.removeSelectedFile(index),
        ),
        onTap: () {
          if (fileType == 'image' && filePath.isNotEmpty) _showImagePreview(context, filePath);
        },
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showImagePreview(BuildContext context, String imagePath) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Aperçu'),
              automaticallyImplyLeading: false,
              actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))],
            ),
            Flexible(child: Image.file(File(imagePath), fit: BoxFit.contain)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFiles(BuildContext context, BonCommandeNotifier notifier) async {
    final selectionType = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sélectionner des fichiers'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.insert_drive_file), title: const Text('Fichiers (PDF, Documents, etc.)'), onTap: () => Navigator.pop(ctx, 'file')),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Image depuis la galerie'), onTap: () => Navigator.pop(ctx, 'gallery')),
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Prendre une photo / Scanner'), onTap: () => Navigator.pop(ctx, 'camera')),
          ],
        ),
      ),
    );
    if (selectionType == null) return;

    if (selectionType == 'file') {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        final toAdd = <Map<String, dynamic>>[];
        for (var platformFile in result.files) {
          if (platformFile.path == null) continue;
          final file = File(platformFile.path!);
          final fileSize = await file.length();
          if (fileSize > 10 * 1024 * 1024) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Le fichier "${platformFile.name}" est trop volumineux (max 10 MB)')));
            continue;
          }
          final extension = platformFile.extension?.toLowerCase() ?? '';
          String type = 'document';
          if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) type = 'image';
          else if (extension == 'pdf') type = 'pdf';
          toAdd.add({'name': platformFile.name, 'path': platformFile.path!, 'size': fileSize, 'type': type, 'extension': extension});
        }
        if (toAdd.isNotEmpty) {
          notifier.addSelectedFiles(toAdd);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${toAdd.length} fichier(s) ajouté(s)')));
        }
      }
    } else {
      try {
        final cameraService = CameraService();
        File? imageFile = selectionType == 'camera' ? await cameraService.takePicture() : await cameraService.pickImageFromGallery();
        if (imageFile != null && await imageFile.exists()) {
          final fileSize = await imageFile.length();
          if (fileSize > 10 * 1024 * 1024) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le fichier est trop volumineux (max 10 MB)')));
            return;
          }
          await cameraService.validateImage(imageFile);
          final fileName = imageFile.path.split('/').last;
          final extension = fileName.split('.').last.toLowerCase();
          notifier.addSelectedFile({'name': fileName, 'path': imageFile.path, 'size': fileSize, 'type': 'image', 'extension': extension});
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fichier ajouté')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString().replaceFirst('Exception: ', '')}')));
      }
    }
  }

  Widget _buildSaveButton(BuildContext context, BonCommandeState state, BonCommandeNotifier notifier) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: state.isLoading
            ? null
            : () async {
                if (formKey.currentState!.validate()) {
                  if (state.selectedClient == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner un client validé'), backgroundColor: Colors.red));
                    return;
                  }
                  if (state.selectedClient!.status != 1) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seuls les clients validés peuvent être sélectionnés'), backgroundColor: Colors.red));
                    return;
                  }
                  if (state.selectedFiles.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez ajouter au moins un fichier scanné'), backgroundColor: Colors.red));
                    return;
                  }
                  try {
                    if (widget.isEditing && widget.bonCommandeId != null) {
                      final success = await notifier.updateBonCommande(widget.bonCommandeId!);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bon de commande mis à jour avec succès')));
                        context.go('/bon-commandes');
                      }
                    } else {
                      final success = await notifier.createBonCommande();
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bon de commande créé avec succès'), backgroundColor: Colors.green));
                        context.go('/bon-commandes');
                      }
                    }
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
                  }
                }
              },
        icon: state.isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save),
        label: Text(state.isLoading ? 'Enregistrement...' : 'Enregistrer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _showClientSelection(BuildContext context, BonCommandeNotifier notifier) {
    showDialog<void>(
      context: context,
      builder: (ctx) => ClientSelectionDialog(
        onClientSelected: (client) {
          notifier.selectClient(client);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}
