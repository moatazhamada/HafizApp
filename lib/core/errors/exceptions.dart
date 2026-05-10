class ServerException implements Exception {}

class CacheException implements Exception {}

class NetworkException implements Exception {}

/// Thrown when no internet connectivity is detected.
/// Pure data-layer exception — no UI coupling.
class NoInternetException implements Exception {
  final String message;

  NoInternetException([this.message = 'NoInternetException Occurred']);

  @override
  String toString() => message;
}
