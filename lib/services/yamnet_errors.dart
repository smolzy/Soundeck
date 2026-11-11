class YamnetException implements Exception {
  const YamnetException(this.message);

  final String message;

  @override
  String toString() => message;
}
