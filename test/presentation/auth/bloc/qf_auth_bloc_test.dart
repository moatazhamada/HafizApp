import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/data/datasource/auth/qf_auth_remote_data_source.dart';
import 'package:hafiz_app/presentation/auth/bloc/qf_auth_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockQfAuthRemoteDataSource extends Mock
    implements QfAuthRemoteDataSource {}

void main() {
  late MockQfAuthRemoteDataSource mockAuthDs;
  late QfAuthBloc bloc;

  setUp(() {
    mockAuthDs = MockQfAuthRemoteDataSource();
    bloc = QfAuthBloc(authRemoteDataSource: mockAuthDs);
  });

  tearDown(() => bloc.close());

  test('initial state is QfAuthInitial', () {
    expect(bloc.state, isA<QfAuthInitial>());
  });

  group('QfAuthCheckRequested', () {
    blocTest<QfAuthBloc, QfAuthState>(
      'emits [QfAuthLoading, QfAuthAuthenticated] when authenticated',
      build: () {
        when(() => mockAuthDs.isAuthenticated())
            .thenAnswer((_) async => true);
        when(() => mockAuthDs.getUserId())
            .thenAnswer((_) async => 'user-123');
        return bloc;
      },
      act: (bloc) => bloc.add(QfAuthCheckRequested()),
      expect: () => [
        isA<QfAuthLoading>(),
        predicate<QfAuthState>(
          (s) => s is QfAuthAuthenticated && s.userId == 'user-123',
        ),
      ],
    );

    blocTest<QfAuthBloc, QfAuthState>(
      'emits [QfAuthLoading, QfAuthUnauthenticated] when not authenticated',
      build: () {
        when(() => mockAuthDs.isAuthenticated())
            .thenAnswer((_) async => false);
        return bloc;
      },
      act: (bloc) => bloc.add(QfAuthCheckRequested()),
      expect: () => [isA<QfAuthLoading>(), isA<QfAuthUnauthenticated>()],
    );

    blocTest<QfAuthBloc, QfAuthState>(
      'emits [QfAuthLoading, QfAuthError] when check throws',
      build: () {
        when(() => mockAuthDs.isAuthenticated())
            .thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (bloc) => bloc.add(QfAuthCheckRequested()),
      expect: () => [isA<QfAuthLoading>(), isA<QfAuthError>()],
    );
  });

  group('QfAuthLoginRequested', () {
    blocTest<QfAuthBloc, QfAuthState>(
      'emits [QfAuthError] when clientId not configured',
      build: () {
        when(() => mockAuthDs.login()).thenAnswer((_) async => true);
        return bloc;
      },
      act: (bloc) => bloc.add(QfAuthLoginRequested()),
      expect: () => [
        predicate<QfAuthState>(
          (s) => s is QfAuthError && s.message == 'msg_login_not_configured',
        ),
      ],
      verify: (_) {
        verifyNever(() => mockAuthDs.login());
      },
    );
  });

  group('QfAuthLogoutRequested', () {
    blocTest<QfAuthBloc, QfAuthState>(
      'emits [QfAuthLoading, QfAuthUnauthenticated] on logout',
      build: () {
        when(() => mockAuthDs.logout()).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(QfAuthLogoutRequested()),
      expect: () => [isA<QfAuthLoading>(), isA<QfAuthUnauthenticated>()],
    );
  });
}
