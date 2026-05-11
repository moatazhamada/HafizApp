import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class QfPkcePair {
  final String codeVerifier;
  final String codeChallenge;

  const QfPkcePair({
    required this.codeVerifier,
    required this.codeChallenge,
  });
}

class QfAuthParams {
  final QfPkcePair pkce;
  final String state;
  final String nonce;

  const QfAuthParams({
    required this.pkce,
    required this.state,
    required this.nonce,
  });
}

class QfPkceGenerator {
  static String _base64url(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _randomString(int bytes) {
    final random = Random.secure();
    final list = List<int>.generate(bytes, (_) => random.nextInt(256));
    return _base64url(list);
  }

  static String _randomHex(int bytes) {
    final random = Random.secure();
    final list = List<int>.generate(bytes, (_) => random.nextInt(256));
    return list.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static QfPkcePair generatePkcePair() {
    final codeVerifier = _randomString(32);
    final hash = sha256.convert(utf8.encode(codeVerifier));
    final codeChallenge = _base64url(hash.bytes);
    return QfPkcePair(
      codeVerifier: codeVerifier,
      codeChallenge: codeChallenge,
    );
  }

  static String generateState() {
    return _randomHex(16);
  }

  static String generateNonce() {
    return _randomHex(16);
  }

  static QfAuthParams generateAuthParams() {
    return QfAuthParams(
      pkce: generatePkcePair(),
      state: generateState(),
      nonce: generateNonce(),
    );
  }
}
