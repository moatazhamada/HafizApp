import 'package:flutter/material.dart';

/// The active home screen layout surface.
/// Each surface prioritizes different features based on user behavior.
enum SurfaceType {
  /// Index-first, large text, minimal chrome. Default for readers.
  reader,

  /// Dashboard-first with progress cards. For students.
  student,

  /// Search-first with discovery cards. For seekers.
  seeker,

  /// Daily rituals, Khatmah tracking, streaks, devotional use.
  devotee;

  String get labelKey => switch (this) {
    SurfaceType.reader => 'lbl_surface_reader',
    SurfaceType.student => 'lbl_surface_student',
    SurfaceType.seeker => 'lbl_surface_seeker',
    SurfaceType.devotee => 'lbl_surface_devotee',
  };

  IconData get icon => switch (this) {
    SurfaceType.reader => Icons.menu_book_outlined,
    SurfaceType.student => Icons.school_outlined,
    SurfaceType.seeker => Icons.explore_outlined,
    SurfaceType.devotee => Icons.mosque_outlined,
  };

  Color get color => switch (this) {
    SurfaceType.reader => const Color(0xFF009688),
    SurfaceType.student => const Color(0xFF2196F3),
    SurfaceType.seeker => const Color(0xFFFF9800),
    SurfaceType.devotee => const Color(0xFF9C27B0),
  };

  static SurfaceType fromString(String? value) => switch (value) {
    'student' => SurfaceType.student,
    'seeker' => SurfaceType.seeker,
    'devotee' => SurfaceType.devotee,
    _ => SurfaceType.reader,
  };

  /// Maps an archetype to its default surface.
  static SurfaceType fromArchetype(String? archetype) => switch (archetype) {
    'student' => SurfaceType.student,
    'seeker' => SurfaceType.seeker,
    'devotee' => SurfaceType.devotee,
    _ => SurfaceType.reader,
  };
}
