/// The active home screen layout surface.
/// Each surface prioritizes different features based on user behavior.
enum SurfaceType {
  /// Index-first, large text, minimal chrome. Default for readers.
  reader,

  /// Dashboard-first with progress cards. For students.
  student,

  /// Search-first with discovery cards. For seekers.
  seeker;

  String get labelKey => switch (this) {
    SurfaceType.reader => 'lbl_surface_reader',
    SurfaceType.student => 'lbl_surface_student',
    SurfaceType.seeker => 'lbl_surface_seeker',
  };

  static SurfaceType fromString(String? value) => switch (value) {
    'student' => SurfaceType.student,
    'seeker' => SurfaceType.seeker,
    _ => SurfaceType.reader,
  };

  /// Maps an archetype to its default surface.
  static SurfaceType fromArchetype(String? archetype) => switch (archetype) {
    'student' => SurfaceType.student,
    'seeker' => SurfaceType.seeker,
    _ => SurfaceType.reader,
  };
}
