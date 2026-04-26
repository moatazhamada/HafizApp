import 'package:dio/dio.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:hafiz_app/core/config/qf_api_config.dart';
import 'package:hafiz_app/core/utils/logger.dart';

abstract class QfAuthRemoteDataSource {
  Future<bool> login();
  Future<void> logout();
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<String?> getUserId();
  Future<bool> refreshToken();
  Future<bool> isAuthenticated();
  Future<void> revokeAndDeleteData();
}

class QfAuthRemoteDataSourceImpl implements QfAuthRemoteDataSource {
  final FlutterAppAuth _appAuth;
  final FlutterSecureStorage _secureStorage;
  final QfApiConfig _config;

  static const String _accessTokenKey = 'qf_access_token';
  static const String _refreshTokenKey = 'qf_refresh_token';
  static const String _idTokenKey = 'qf_id_token';

  QfAuthRemoteDataSourceImpl({
    FlutterAppAuth? appAuth,
    FlutterSecureStorage? secureStorage,
    QfApiConfig? config,
  })  : _appAuth = appAuth ?? const FlutterAppAuth(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _config = config ?? const QfApiConfig();

  @override
  Future<bool> login() async {
    try {
      final AuthorizationTokenResponse result =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          QfApiConfig.clientId,
          QfApiConfig.redirectUri,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: _config.authorizationEndpoint,
            tokenEndpoint: _config.tokenEndpoint,
          ),
          scopes: QfApiConfig.scopes,
        ),
      );

      if (result.accessToken != null) {        await _saveTokens(result);
        Logger.info('Successfully logged in via QF OAuth', feature: 'QfAuth');
        return true;
      }
      Logger.warning('Login returned null response — user may have cancelled', feature: 'QfAuth');
      return false;
    } on FlutterAppAuthUserCancelledException {
      Logger.info('User cancelled login', feature: 'QfAuth');
      return false;
    } catch (e) {
      Logger.error('Login failed: $e', feature: 'QfAuth');
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _idTokenKey);
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
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final TokenResponse result = await _appAuth.token(
        TokenRequest(
          QfApiConfig.clientId,
          QfApiConfig.redirectUri,
          refreshToken: refreshToken,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: _config.authorizationEndpoint,
            tokenEndpoint: _config.tokenEndpoint,
          ),
          scopes: QfApiConfig.scopes,
        ),
      );

      if (result.accessToken != null) {        await _saveTokens(result);
        Logger.info('Successfully refreshed QF tokens', feature: 'QfAuth');
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Failed to refresh token: $e', feature: 'QfAuth');
      // If refresh fails (e.g., refresh token expired or revoked), clear local tokens
      await logout();
      return false;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return false;

    // Check if the idToken is expired as a proxy for access token.
    // If we only had an access token, we might need to rely on api calls to know for sure,
    // or just assume true and let interceptor handle 401s.
    final idToken = await _secureStorage.read(key: _idTokenKey);
    if (idToken != null && JwtDecoder.isExpired(idToken)) {
      // Try to refresh
      return await refreshToken();
    }
    return true;
  }

  @override
  Future<void> revokeAndDeleteData() async {
    // Attempt to revoke the refresh token with QF's revocation endpoint
    try {
      final token = await getRefreshToken();
      if (token != null) {
        await Dio().post(
          '${_config.authBaseUrl}/oauth2/revoke',
          data: 'token=$token&client_id=${QfApiConfig.clientId}',
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
          ),
        );
        Logger.info('QF token revoked', feature: 'QfAuth');
      }
    } catch (e) {
      Logger.warning('Token revocation failed (continuing with local cleanup): $e',
          feature: 'QfAuth');
    }

    // Clear all local tokens regardless of revocation result
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
      await _secureStorage.write(
        key: _idTokenKey,
        value: response.idToken,
      );
    }
  }
}
