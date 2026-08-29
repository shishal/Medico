/// Postgres `attempt_status` enum.
enum AttemptStatus {
  inProgress,
  submitted,
  abandoned;

  static AttemptStatus fromString(String value) {
    return switch (value.trim().toLowerCase()) {
      'submitted' => AttemptStatus.submitted,
      'abandoned' => AttemptStatus.abandoned,
      _ => AttemptStatus.inProgress,
    };
  }

  String get dbValue => switch (this) {
    AttemptStatus.inProgress => 'in_progress',
    AttemptStatus.submitted => 'submitted',
    AttemptStatus.abandoned => 'abandoned',
  };
}

/// Local file status. [pendingSubmit] is written in Phase 6.1; 5.1 only
/// uses [inProgress]. Kept here so the snapshot schema does not change later.
enum LocalAttemptStatus {
  inProgress,
  pendingSubmit;

  static LocalAttemptStatus fromString(String value) {
    return switch (value.trim().toLowerCase()) {
      'pending_submit' => LocalAttemptStatus.pendingSubmit,
      _ => LocalAttemptStatus.inProgress,
    };
  }

  String get jsonValue => switch (this) {
    LocalAttemptStatus.inProgress => 'in_progress',
    LocalAttemptStatus.pendingSubmit => 'pending_submit',
  };
}
