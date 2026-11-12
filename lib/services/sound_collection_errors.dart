class SoundCollectionException implements Exception {
  const SoundCollectionException(this.message);

  final String message;

  @override
  String toString() => message;
}
