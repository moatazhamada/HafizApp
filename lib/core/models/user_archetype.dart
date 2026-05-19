import 'package:flutter/material.dart';

/// Represents the user's primary mental model for using the app.
/// Detected during onboarding and refined via behavior tracking.
enum UserArchetype {
  /// Default — reads sequentially, wants simplicity and familiarity.
  /// Elderly-friendly. Surah index dominates.
  reader,

  /// Memorizing, tracking progress, using practice lists and goals.
  student,

  /// Searching, exploring meanings, looking up verses.
  seeker,

  /// Daily rituals, Khatmah tracking, streaks, devotional use.
  devotee;

  String get labelKey => switch (this) {
    UserArchetype.reader => 'lbl_archetype_reader',
    UserArchetype.student => 'lbl_archetype_student',
    UserArchetype.seeker => 'lbl_archetype_seeker',
    UserArchetype.devotee => 'lbl_archetype_devotee',
  };

  String get descriptionKey => switch (this) {
    UserArchetype.reader => 'msg_archetype_reader_desc',
    UserArchetype.student => 'msg_archetype_student_desc',
    UserArchetype.seeker => 'msg_archetype_seeker_desc',
    UserArchetype.devotee => 'msg_archetype_devotee_desc',
  };

  IconData get icon => switch (this) {
    UserArchetype.reader => Icons.menu_book_rounded,
    UserArchetype.student => Icons.school_rounded,
    UserArchetype.seeker => Icons.search_rounded,
    UserArchetype.devotee => Icons.mosque_rounded,
  };

  int get colorValue => switch (this) {
    UserArchetype.reader => 0xFF009688,
    UserArchetype.student => 0xFF2196F3,
    UserArchetype.seeker => 0xFFFF9800,
    UserArchetype.devotee => 0xFF9C27B0,
  };

  static UserArchetype fromString(String? value) => switch (value) {
    'student' => UserArchetype.student,
    'seeker' => UserArchetype.seeker,
    'devotee' => UserArchetype.devotee,
    _ => UserArchetype.reader,
  };

  static const List<UserArchetype> all = UserArchetype.values;
}
