import 'package:dio/dio.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:hafiz_app/core/auth/qf_backend_proxy.dart';
import 'package:hafiz_app/core/auth/qf_oidc_config.dart';
import 'package:hafiz_app/core/auth/qf_pkce.dart';
import 'package:hafiz_app/core/auth/qf_token_validator.dart';
import 'package:hafiz_app/core/config/qf_api_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';
import 'package:hafiz_app/domain/entities/qf_user_profile.dart';

abstract class QfAuthRemoteDataSource {
  Future<bool> login();
  Future<void> logout();
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<String?> getUserId();
  Future<QfUserProfile?> getUserProfile();
  Future<bool> refreshToken();
  Future<bool> isAuthenticated();
  Future<void> revokeAndDeleteData();
}

class QfAuthRemoteDataSourceImpl implements QfAuthRemoteDataSource {
  final FlutterAppAuth _appAuth;
  final FlutterSecureStorage _secureStorage;
  final QfApiConfig _config;
  final QfOidcConfig _oidcConfig;
  final QfBackendTokenProxy _backendProxy;

  static const String _accessTokenKey = 'qf_access_token';
  static const String _refreshTokenKey = 'qf_refresh_token';
  static const String _idTokenKey = 'qf_id_token';
  static const String _oidcNonceKey = 'qf_oidc_nonce';

  QfAuthRemoteDataSourceImpl({
    FlutterAppAuth? appAuth,
    FlutterSecureStorage? secureStorage,
    QfApiConfig? config,
    QfOidcConfig? oidcConfig,
    QfBackendTokenProxy? backendProxy,
  }) : _appAuth = appAuth ?? const FlutterAppAuth(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _config = config ?? const QfApiConfig(),
       _oidcConfig = oidcConfig ?? QfOidcConfig.fromQfApiConfig(const QfApiConfig()),
       _backendProxy = backendProxy ?? QfNoopBackendTokenProxy();

  bool _isInvalidScopeError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('invalid_scope');
  }

  String? _extractRejectedScope(Object e) {
    final msg = e.toString().toLowerCase();
    for (final scope in QfApiConfig.scopes) {
      if (msg.contains(scope.toLowerCase())) return scope;
    }
    return null;
  }

  @override
  Future<bool> login() async {
    try {
      return await _loginWithFallback();
    } on FlutterAppAuthUserCancelledException {
      Logger.info('User cancelled login', feature: 'QfAuth');
      return false;
    } catch (e) {
      Logger.error('Login failed: $e', feature: 'QfAuth');
      rethrow;
    }
  }

  Future<bool> _loginWithFallback() async {
    List<String> scopes = List.from(QfApiConfig.scopes);

    while (true) {
      try {
        return await _loginWithScopes(scopes);
      } catch (e) {
        if (_isInvalidScopeError(e)) {
          final rejected = _extractRejectedScope(e);
          if (rejected != null &&
              !QfApiConfig.coreScopes.contains(rejected) &&
              scopes.contains(rejected)) {
            Logger.warning(
              'Scope "$rejected" rejected by server, retrying without it',
              feature: 'QfAuth',
            );
            scopes = List.from(scopes)..remove(rejected);
            if (scopes.isNotEmpty) continue;
          }
          if (!_everyScopeInCore(scopes)) {
            Logger.warning(
              'Falling back to core scopes only',
              feature: 'QfAuth',
            );
            return await _loginWithScopes(QfApiConfig.coreScopes);
          }
        }
        rethrow;
      }
    }
  }

  bool _everyScopeInCore(List<String> scopes) =>
      scopes.every((s) => QfApiConfig.coreScopes.contains(s));

  Future<bool> _loginWithScopes(List<String> scopes) async {
    final nonce = QfPkceGenerator.generateNonce();
    await _secureStorage.write(key: _oidcNonceKey, value: nonce);

    final scopesIncludeOpenid = scopes.any(
      (s) => s.toLowerCase() == 'openid',
    );

    if (_oidcConfig.isConfidential && QfApiConfig.backendExchangeUrl.isNotEmpty) {
      return await _loginConfidential(scopes, nonce);
    }

    if (_oidcConfig.isConfidential && QfApiConfig.clientSecret.isNotEmpty) {
      Logger.warning(
        'Confidential client using direct in-app token exchange. '
        'The client_secret is embedded in the app — this is NOT the recommended '
        'pattern. Use QF_BACKEND_EXCHANGE_URL to move token exchange to a backend server.',
        feature: 'QfAuth',
      );
    }

    return await _loginPublic(scopes, nonce, scopesIncludeOpenid);
  }

  Future<bool> _loginConfidential(
    List<String> scopes,
    String nonce,
  ) async {
    final authorizationRequest = AuthorizationRequest(
      QfApiConfig.clientId,
      QfApiConfig.redirectUri,
      serviceConfiguration: AuthorizationServiceConfiguration(
        authorizationEndpoint: _config.authorizationEndpoint,
        tokenEndpoint: _config.tokenEndpoint,
      ),
      scopes: scopes,
      nonce: scopes.any((s) => s.toLowerCase() == 'openid') ? nonce : null,
    );

    final authResponse = await _appAuth.authorize(authorizationRequest);
    if (authResponse.authorizationCode == null) {
      Logger.warning(
        'Authorization returned null response',
        feature: 'QfAuth',
      );
      await _secureStorage.delete(key: _oidcNonceKey);
      return false;
    }

    try {
      final result = await _backendProxy.exchangeCodeForTokens(
        code: authResponse.authorizationCode!,
        redirectUri: QfApiConfig.redirectUri,
        codeVerifier: authResponse.codeVerifier ?? '',
      );

      final idToken = result.idToken;

      if (idToken != null && idToken.isNotEmpty) {
        final validator = QfTokenValidator(
          config: _oidcConfig,
          expectedNonce: nonce,
        );
        validator.validateIdToken(idToken);
      }

      await _saveTokensFromExchangeResult(result);
      await _secureStorage.delete(key: _oidcNonceKey);
      Logger.info(
        'Successfully logged in via QF OAuth (confidential/backend)',
        feature: 'QfAuth',
      );
      return true;
    } catch (e) {
      await _secureStorage.delete(key: _oidcNonceKey);
      rethrow;
    }
  }

  Future<bool> _loginPublic(
    List<String> scopes,
    String nonce,
    bool scopesIncludeOpenid,
  ) async {
    final clientSecret = _oidcConfig.isPublic ? null : QfApiConfig.clientSecret;

    final AuthorizationTokenResponse result = await _appAuth
        .authorizeAndExchangeCode(
          AuthorizationTokenRequest(
            QfApiConfig.clientId,
            QfApiConfig.redirectUri,
            clientSecret: clientSecret,
            serviceConfiguration: AuthorizationServiceConfiguration(
              authorizationEndpoint: _config.authorizationEndpoint,
              tokenEndpoint: _config.tokenEndpoint,
            ),
            scopes: scopes,
            nonce: scopesIncludeOpenid ? nonce : null,
          ),
        );

    if (result.accessToken != null) {
      if (result.idToken != null && result.idToken!.isNotEmpty) {
        final validator = QfTokenValidator(
          config: _oidcConfig,
          expectedNonce: scopesIncludeOpenid ? nonce : null,
        );
        validator.validateIdToken(result.idToken);
      }

      await _saveTokens(result);
      await _secureStorage.delete(key: _oidcNonceKey);
      Logger.info(
        'Successfully logged in via QF OAuth (direct/public)',
        feature: 'QfAuth',
      );
      return true;
    }
    await _secureStorage.delete(key: _oidcNonceKey);
    Logger.warning(
      'Login returned null response',
      feature: 'QfAuth',
    );
    return false;
  }

  @override
  Future<void> logout() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _idTokenKey);
    await _secureStorage.delete(key: _oidcNonceKey);
    await _secureStorage.delete(key: QfApiConfig.storedFlavorKey);
    Logger.info('Logged out from QF', feature: 'QfAuth');
  }

  @override
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  @override
  Future<String?> getUserId() async {
    final idToken = await _secureStorage.read(key: _idTokenKey);
    if (idToken != null) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(idToken);
      return decodedToken['sub'] as String?;
    }
    return null;
  }

  @override
  Future<QfUserProfile?> getUserProfile() async {
    final idToken = await _secureStorage.read(key: _idTokenKey);
    if (idToken != null) {
      try {
        final claims = JwtDecoder.decode(idToken);
        return QfUserProfile.fromIdTokenClaims(claims);
      } catch (e) {
        Logger.warning('Failed to decode user profile from ID token: $e',
            feature: 'QfAuth');
        return null;
      }
    }
    return null;
  }

  @override
  Future<bool> refreshToken() async {
    try {
      return await _refreshWithFallback();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        Logger.error(
          'Token refresh rejected ($statusCode), logging out',
          feature: 'QfAuth',
        );
        await logout();
      } else {
        Logger.error(
          'Token refresh failed with network error: $e',
          feature: 'QfAuth',
        );
      }
      return false;
    } catch (e) {
      Logger.error('Token refresh failed unexpectedly: $e', feature: 'QfAuth');
      return false;
    }
  }

  Future<bool> _refreshWithFallback() async {
    List<String> scopes = List.from(QfApiConfig.scopes);

    while (true) {
      try {
        return await _refreshWithScopes(scopes);
      } catch (e) {
        if (_isInvalidScopeError(e)) {
          final rejected = _extractRejectedScope(e);
          if (rejected != null &&
              !QfApiConfig.coreScopes.contains(rejected) &&
              scopes.contains(rejected)) {
            Logger.warning(
              'Token refresh: scope "$rejected" rejected, retrying without it',
              feature: 'QfAuth',
            );
            scopes = List.from(scopes)..remove(rejected);
            if (scopes.isNotEmpty) continue;
          }
          if (!_everyScopeInCore(scopes)) {
            Logger.warning(
              'Token refresh: falling back to core scopes only',
              feature: 'QfAuth',
            );
            try {
              return await _refreshWithScopes(QfApiConfig.coreScopes);
            } catch (e) {
              Logger.warning('Token refresh with core scopes failed: $e', feature: 'QfAuth');
              await logout();
              return false;
            }
          }
        }
        rethrow;
      }
    }
  }

  Future<bool> _refreshWithScopes(List<String> scopes) async {
    final storedRefreshToken = await getRefreshToken();
    if (storedRefreshToken == null) return false;

    if (_oidcConfig.isConfidential &&
        QfApiConfig.backendExchangeUrl.isNotEmpty) {
      try {
        final result = await _backendProxy.refreshAccessToken(
          refreshToken: storedRefreshToken,
        );
        await _saveTokensFromExchangeResult(result);
        Logger.info(
          'Successfully refreshed QF tokens (via backend)',
          feature: 'QfAuth',
        );
        return true;
      } catch (e) {
        Logger.error(
          'Backend token refresh failed: $e',
          feature: 'QfAuth',
        );
        return false;
      }
    }

    final clientSecret =
        _oidcConfig.isPublic ? null : QfApiConfig.clientSecret;

    final TokenResponse result = await _appAuth.token(
      TokenRequest(
        QfApiConfig.clientId,
        QfApiConfig.redirectUri,
        refreshToken: storedRefreshToken,
        clientSecret: clientSecret,
        serviceConfiguration: AuthorizationServiceConfiguration(
          authorizationEndpoint: _config.authorizationEndpoint,
          tokenEndpoint: _config.tokenEndpoint,
        ),
        scopes: scopes,
      ),
    );

    if (result.accessToken != null) {
      await _saveTokens(result);
      Logger.info(
        'Successfully refreshed QF tokens (direct)',
        feature: 'QfAuth',
      );
      return true;
    }
    return false;
  }

  @override
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return false;

    final storedFlavor = await _secureStorage.read(
      key: QfApiConfig.storedFlavorKey,
    );
    if (storedFlavor != null && storedFlavor != QfApiConfig.currentFlavor) {
      Logger.warning(
        'Flavor mismatch: stored=$storedFlavor current=${QfApiConfig.currentFlavor}. '
        'Clearing stale tokens.',
        feature: 'QfAuth',
      );
      await logout();
      return false;
    }

    final idToken = await _secureStorage.read(key: _idTokenKey);
    if (idToken != null && JwtDecoder.isExpired(idToken)) {
      return await refreshToken();
    }
    return true;
  }

  @override
  Future<void> revokeAndDeleteData() async {
    try {
      final token = await getRefreshToken();
      if (token != null) {
        await Dio().post(
          '${_config.authBaseUrl}/oauth2/revoke',
          data: 'token=$token&client_id=${QfApiConfig.clientId}',
          options: Options(contentType: Headers.formUrlEncodedContentType),
        );
        Logger.info('QF token revoked', feature: 'QfAuth');
      }
    } catch (e) {
      Logger.warning(
        'Token revocation failed (continuing with local cleanup): $e',
        feature: 'QfAuth',
      );
    }

    await logout();
    Logger.info('All QF data deleted', feature: 'QfAuth');
  }

  Future<void> _saveTokens(TokenResponse response) async {
    if (response.accessToken != null) {
      await _secureStorage.write(
        key: _accessTokenKey,
        value: response.accessToken,
      );
    }
    if (response.refreshToken != null) {
      await _secureStorage.write(
        key: _refreshTokenKey,
        value: response.refreshToken,
      );
    }
    if (response.idToken != null) {
      await _secureStorage.write(key: _idTokenKey, value: response.idToken);
    }
    await _secureStorage.write(
      key: QfApiConfig.storedFlavorKey,
      value: QfApiConfig.currentFlavor,
    );
  }

  Future<void> _saveTokensFromExchangeResult(
    QfBackendTokenExchangeResult result,
  ) async {
    await _secureStorage.write(
      key: _accessTokenKey,
      value: result.accessToken,
    );
    if (result.refreshToken != null) {
      await _secureStorage.write(
        key: _refreshTokenKey,
        value: result.refreshToken,
      );
    }
    if (result.idToken != null) {
      await _secureStorage.write(key: _idTokenKey, value: result.idToken);
    }
    await _secureStorage.write(
      key: QfApiConfig.storedFlavorKey,
      value: QfApiConfig.currentFlavor,
    );
  }
}
