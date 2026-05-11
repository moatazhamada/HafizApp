import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:hafiz_app/core/auth/qf_oidc_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

class QfTokenValidationError {
  final String message;
  const QfTokenValidationError(this.message);

  @override
  String toString() => 'QfTokenValidationError: $message';
}

class QfTokenValidator {
  final QfOidcConfig _config;
  final String? _expectedState;
  final String? _expectedNonce;

  const QfTokenValidator({
    required QfOidcConfig config,
    String? expectedState,
    String? expectedNonce,
  }) : _config = config,
       _expectedState = expectedState,
       _expectedNonce = expectedNonce;

  void validateState(String? returnedState) {
    if (_expectedState == null) return;

    if (returnedState == null || returnedState.isEmpty) {
      throw const QfTokenValidationError(
        'OAuth2 state not returned in callback — possible CSRF attack',
      );
    }

    if (returnedState != _expectedState) {
      Logger.warning(
        'OAuth2 state mismatch — possible CSRF attack. '
        'Expected: ${_expectedState.hashCode}, Got: ${returnedState.hashCode}',
        feature: 'QfTokenValidator',
      );
      throw const QfTokenValidationError(
        'OAuth2 state mismatch — possible CSRF attack',
      );
    }
  }

  void validateNonceInIdToken(String? idToken) {
    if (_expectedNonce == null) {
      Logger.debug(
        'No nonce expected — skipping nonce validation',
        feature: 'QfTokenValidator',
      );
      return;
    }

    if (idToken == null || idToken.isEmpty) {
      Logger.warning(
        'ID token is null or empty but a nonce was expected',
        feature: 'QfTokenValidator',
      );
      throw const QfTokenValidationError(
        'ID token missing — expected for nonce validation',
      );
    }

    final decoded = _decodeIdToken(idToken);

    final nonceClaim = decoded['nonce'] as String?;
    if (nonceClaim == null || nonceClaim.isEmpty) {
      Logger.warning(
        'ID token has no nonce claim but nonce was expected',
        feature: 'QfTokenValidator',
      );
      throw const QfTokenValidationError(
        'ID token missing nonce claim — nonce was expected',
      );
    }

    if (nonceClaim != _expectedNonce) {
      Logger.warning(
        'ID token nonce mismatch. '
        'Expected hash: ${_expectedNonce.hashCode}, '
        'Got hash: ${nonceClaim.hashCode}',
        feature: 'QfTokenValidator',
      );
      throw const QfTokenValidationError(
        'ID token nonce mismatch — possible token replay attack',
      );
    }
  }

  void validateIdTokenClaims(String idToken) {
    final decoded = _decodeIdToken(idToken);

    final iss = decoded['iss'] as String?;
    if (iss == null ||
        !iss.startsWith(_config.endpoints.authBaseUrl)) {
      Logger.warning(
        'ID token iss claim mismatch. '
        'Expected: ${_config.endpoints.authBaseUrl}, Got: $iss',
        feature: 'QfTokenValidator',
      );
      throw const QfTokenValidationError(
        'ID token issuer (iss) mismatch',
      );
    }

    final aud = decoded['aud'];
    final audList = aud is List ? aud : [aud];
    if (!audList.any(
      (a) => a == _config.clientId || a == 'quran-demo',
    )) {
      Logger.warning(
        'ID token aud claim does not match client_id. '
        'Expected: ${_config.clientId}, Got: $aud',
        feature: 'QfTokenValidator',
      );
      throw const QfTokenValidationError(
        'ID token audience (aud) does not match client_id',
      );
    }

    final exp = decoded['exp'] as int?;
    if (exp == null) {
      throw const QfTokenValidationError(
        'ID token missing expiration (exp) claim',
      );
    }

    final expiryMs = exp * 1000;
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    if (nowMs > expiryMs) {
      throw const QfTokenValidationError(
        'ID token has expired',
      );
    }
  }

  void validateIdToken(String? idToken) {
    if (idToken == null || idToken.isEmpty) {
      Logger.warning(
        'ID token is null or empty — cannot validate',
        feature: 'QfTokenValidator',
      );
      throw const QfTokenValidationError(
        'ID token missing — expected for OpenID Connect authentication',
      );
    }

    validateIdTokenClaims(idToken);

    if (_expectedNonce != null) {
      validateNonceInIdToken(idToken);
    }
  }

  Map<String, dynamic> _decodeIdToken(String idToken) {
    try {
      return JwtDecoder.decode(idToken);
    } catch (e) {
      Logger.error(
        'Failed to decode ID token: $e',
        feature: 'QfTokenValidator',
      );
      throw const QfTokenValidationError(
        'Failed to decode ID token',
      );
    }
  }

  String decodeUserId(String? idToken) {
    if (idToken == null || idToken.isEmpty) {
      throw const QfTokenValidationError(
        'ID token missing — cannot extract user sub claim',
      );
    }

    final decoded = _decodeIdToken(idToken);
    final sub = decoded['sub'] as String?;
    if (sub == null || sub.isEmpty) {
      throw const QfTokenValidationError(
        'ID token missing sub claim',
      );
    }
    return sub;
  }
}
