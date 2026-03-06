import 'package:flutter_inappwebview/flutter_inappwebview.dart';

enum ShellSection {
  reservation,
  order,
  signature,
  wallet,
}

class ShellNavigationState {
  const ShellNavigationState({
    required this.currentSection,
    required this.inWeb,
    required this.loadingWeb,
    this.webTitle,
    this.errorText,
    this.pendingRequest,
    this.sectionLastActiveAt = const <ShellSection, DateTime>{},
  });

  factory ShellNavigationState.initial() {
    return const ShellNavigationState(
      currentSection: ShellSection.reservation,
      inWeb: false,
      loadingWeb: false,
    );
  }

  final ShellSection currentSection;
  final bool inWeb;
  final bool loadingWeb;
  final String? webTitle;
  final String? errorText;
  final URLRequest? pendingRequest;
  final Map<ShellSection, DateTime> sectionLastActiveAt;

  ShellNavigationState copyWith({
    ShellSection? currentSection,
    bool? inWeb,
    bool? loadingWeb,
    String? webTitle,
    bool clearWebTitle = false,
    String? errorText,
    bool clearErrorText = false,
    URLRequest? pendingRequest,
    bool clearPendingRequest = false,
    Map<ShellSection, DateTime>? sectionLastActiveAt,
  }) {
    return ShellNavigationState(
      currentSection: currentSection ?? this.currentSection,
      inWeb: inWeb ?? this.inWeb,
      loadingWeb: loadingWeb ?? this.loadingWeb,
      webTitle: clearWebTitle ? null : (webTitle ?? this.webTitle),
      errorText: clearErrorText ? null : (errorText ?? this.errorText),
      pendingRequest:
          clearPendingRequest ? null : (pendingRequest ?? this.pendingRequest),
      sectionLastActiveAt: sectionLastActiveAt ?? this.sectionLastActiveAt,
    );
  }

  ShellNavigationState markSectionActive(ShellSection section) {
    return copyWith(
      sectionLastActiveAt: <ShellSection, DateTime>{
        ...sectionLastActiveAt,
        section: DateTime.now(),
      },
    );
  }

  ShellNavigationState markSectionStale(ShellSection section) {
    final updated = Map<ShellSection, DateTime>.from(sectionLastActiveAt);
    updated.remove(section);
    return copyWith(sectionLastActiveAt: updated);
  }

  bool isSectionStale(
    ShellSection section, {
    Duration threshold = const Duration(seconds: 30),
  }) {
    final last = sectionLastActiveAt[section];
    if (last == null) return true;
    return DateTime.now().difference(last) > threshold;
  }

  ShellNavigationState enteringWeb({
    required String title,
    required URLRequest request,
    required bool controllerReady,
  }) {
    return copyWith(
      inWeb: true,
      loadingWeb: true,
      webTitle: title,
      clearErrorText: true,
      pendingRequest: controllerReady ? null : request,
      clearPendingRequest: controllerReady,
    );
  }

  ShellNavigationState leavingWeb() {
    return copyWith(
      inWeb: false,
      loadingWeb: false,
      clearWebTitle: true,
      clearErrorText: true,
      clearPendingRequest: true,
    );
  }

  ShellNavigationState selectSection(ShellSection section) {
    return copyWith(
      currentSection: section,
      inWeb: false,
      loadingWeb: false,
      clearWebTitle: true,
      clearErrorText: true,
      clearPendingRequest: true,
    );
  }
}
