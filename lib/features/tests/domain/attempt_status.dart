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

/// Local file status. [pendingSubmit] is set when the timer hits zero (Phase
/// 5.3) or when a submit request is waiting for the network (Phase 6.1).
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
