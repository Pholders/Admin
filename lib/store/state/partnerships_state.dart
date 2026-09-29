import 'package:equatable/equatable.dart';

import '../../features/partnerships/domain/entities/partnership_overview.dart';
import '../../features/partnerships/domain/entities/pharmacy_group.dart';

/// State for the Pharmacies and Partnerships screens.
///
/// The directory and the overview load independently — the Pharmacies screen
/// needs only the first, the Partnerships screen only the second — so each
/// carries its own loading and error flags rather than sharing one.
class PartnershipsState extends Equatable {
  const PartnershipsState({
    this.directory = const PharmacyDirectory.empty(),
    this.isLoadingDirectory = false,
    this.directoryError,
    this.directoryLoadedAt,
    this.overview,
    this.isLoadingOverview = false,
    this.overviewError,
    this.overviewLoadedAt,
    this.isMutating = false,
    this.actionMessage,
    this.actionError,
  });

  factory PartnershipsState.initial() => const PartnershipsState();

  final PharmacyDirectory directory;
  final bool isLoadingDirectory;
  final String? directoryError;
  final DateTime? directoryLoadedAt;

  final PartnershipOverview? overview;
  final bool isLoadingOverview;
  final String? overviewError;
  final DateTime? overviewLoadedAt;

  /// A create/update/activate/suspend call is in flight. Screens disable
  /// their action controls on this rather than tracking per-row state.
  final bool isMutating;

  final String? actionMessage;
  final String? actionError;

  /// True once a directory load has finished, successfully or not — used to
  /// tell "nothing yet" apart from "genuinely empty".
  bool get hasLoadedDirectory => directoryLoadedAt != null;

  bool get hasLoadedOverview => overviewLoadedAt != null;

  PartnershipsState copyWith({
    PharmacyDirectory? directory,
    bool? isLoadingDirectory,
    String? directoryError,
    DateTime? directoryLoadedAt,
    PartnershipOverview? overview,
    bool? isLoadingOverview,
    String? overviewError,
    DateTime? overviewLoadedAt,
    bool? isMutating,
    String? actionMessage,
    String? actionError,
    bool clearDirectoryError = false,
    bool clearOverviewError = false,
    bool clearActionMessages = false,
  }) {
    return PartnershipsState(
      directory: directory ?? this.directory,
      isLoadingDirectory: isLoadingDirectory ?? this.isLoadingDirectory,
      directoryError:
          clearDirectoryError ? null : (directoryError ?? this.directoryError),
      directoryLoadedAt: directoryLoadedAt ?? this.directoryLoadedAt,
      overview: overview ?? this.overview,
      isLoadingOverview: isLoadingOverview ?? this.isLoadingOverview,
      overviewError:
          clearOverviewError ? null : (overviewError ?? this.overviewError),
      overviewLoadedAt: overviewLoadedAt ?? this.overviewLoadedAt,
      isMutating: isMutating ?? this.isMutating,
      actionMessage:
          clearActionMessages ? null : (actionMessage ?? this.actionMessage),
      actionError:
          clearActionMessages ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
        directory,
        isLoadingDirectory,
        directoryError,
        directoryLoadedAt,
        overview,
        isLoadingOverview,
        overviewError,
        overviewLoadedAt,
        isMutating,
        actionMessage,
        actionError,
      ];
}
