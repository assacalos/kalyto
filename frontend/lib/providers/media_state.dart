import 'package:flutter/foundation.dart';
import 'package:easyconnect/Models/media_model.dart';

@immutable
class MediaState {
  final Map<String, List<MediaItem>> mediaByCategory;
  final String selectedCategory;
  final bool isLoading;
  final List<MediaItem> allMedia;

  MediaState({
    Map<String, List<MediaItem>>? mediaByCategory,
    this.selectedCategory = 'all',
    this.isLoading = false,
    List<MediaItem>? allMedia,
  })  : mediaByCategory = mediaByCategory ?? {},
        allMedia = allMedia ?? [];

  MediaState copyWith({
    Map<String, List<MediaItem>>? mediaByCategory,
    String? selectedCategory,
    bool? isLoading,
    List<MediaItem>? allMedia,
  }) {
    return MediaState(
      mediaByCategory: mediaByCategory ?? this.mediaByCategory,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      allMedia: allMedia ?? this.allMedia,
    );
  }
}
