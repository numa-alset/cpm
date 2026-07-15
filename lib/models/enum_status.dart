enum Status {
  notScheduled,
  scheduled,
  completed,
  shared;

  String get value => name;

  static Status fromString(String value) {
    return Status.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Status.notScheduled,
    );
  }
}
