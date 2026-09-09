class UserBalance {
  final double sy;
  final double dollar;

  const UserBalance({
    required this.sy,
    required this.dollar,
  });

  bool get isZero => sy == 0 && dollar == 0;
}
