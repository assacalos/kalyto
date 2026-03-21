import 'package:easyconnect/Models/besoin_model.dart';

class BesoinState {
  final List<Besoin> besoins;
  final bool isLoading;
  final String selectedStatus;
  final bool isTechnicien;
  final bool canMarkTreated;

  const BesoinState({
    this.besoins = const [],
    this.isLoading = false,
    this.selectedStatus = 'all',
    this.isTechnicien = false,
    this.canMarkTreated = true,
  });

  BesoinState copyWith({
    List<Besoin>? besoins,
    bool? isLoading,
    String? selectedStatus,
    bool? isTechnicien,
    bool? canMarkTreated,
  }) {
    return BesoinState(
      besoins: besoins ?? this.besoins,
      isLoading: isLoading ?? this.isLoading,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      isTechnicien: isTechnicien ?? this.isTechnicien,
      canMarkTreated: canMarkTreated ?? this.canMarkTreated,
    );
  }
}
