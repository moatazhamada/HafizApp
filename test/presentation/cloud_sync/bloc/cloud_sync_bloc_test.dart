import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/usecase/usecase.dart';
import 'package:hafiz_app/domain/repository/cloud_sync_repository.dart';
import 'package:hafiz_app/domain/usecase/cloud_sync/cloud_sync_usecase.dart';
import 'package:hafiz_app/presentation/cloud_sync/bloc/cloud_sync_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockPerformCloudSync extends Mock implements PerformCloudSync {}

class MockCheckCloudSyncAuth extends Mock implements CheckCloudSyncAuth {}

class MockSignInCloudSync extends Mock implements SignInCloudSync {}

class MockSignOutCloudSync extends Mock implements SignOutCloudSync {}

void main() {
  late MockPerformCloudSync mockPerformCloudSync;
  late MockCheckCloudSyncAuth mockCheckAuth;
  late MockSignInCloudSync mockSignIn;
  late MockSignOutCloudSync mockSignOut;

  setUp(() {
    mockPerformCloudSync = MockPerformCloudSync();
    mockCheckAuth = MockCheckCloudSyncAuth();
    mockSignIn = MockSignInCloudSync();
    mockSignOut = MockSignOutCloudSync();

    registerFallbackValue(NoParams());
    registerFallbackValue(SyncDirection.localToRemote);
    registerFallbackValue(const ParamsCloudSync());
  });

  CloudSyncBloc createBloc() => CloudSyncBloc(
    performCloudSync: mockPerformCloudSync,
    checkCloudSyncAuth: mockCheckAuth,
    signInCloudSync: mockSignIn,
    signOutCloudSync: mockSignOut,
  );

  test('initial state is CloudSyncInitial', () {
    final bloc = createBloc();
    expect(bloc.state, isA<CloudSyncInitial>());
    bloc.close();
  });

  blocTest<CloudSyncBloc, CloudSyncState>(
    'CheckAuthStatusEvent emits [Loading, Authenticated(true)] when authenticated',
    setUp: () {
      when(
        () => mockCheckAuth(any()),
      ).thenAnswer((_) async => const Right(true));
    },
    build: createBloc,
    act: (bloc) => bloc.add(CheckAuthStatusEvent()),
    expect: () => [CloudSyncLoading(), const CloudSyncAuthenticated(true)],
  );

  blocTest<CloudSyncBloc, CloudSyncState>(
    'CheckAuthStatusEvent emits [Loading, Authenticated(false)] when not authenticated',
    setUp: () {
      when(
        () => mockCheckAuth(any()),
      ).thenAnswer((_) async => const Right(false));
    },
    build: createBloc,
    act: (bloc) => bloc.add(CheckAuthStatusEvent()),
    expect: () => [CloudSyncLoading(), const CloudSyncAuthenticated(false)],
  );

  blocTest<CloudSyncBloc, CloudSyncState>(
    'SignInEvent emits [Loading, Authenticated(true)] on success',
    setUp: () {
      when(() => mockSignIn(any())).thenAnswer((_) async => const Right(null));
    },
    build: createBloc,
    act: (bloc) => bloc.add(SignInEvent()),
    expect: () => [CloudSyncLoading(), const CloudSyncAuthenticated(true)],
  );

  blocTest<CloudSyncBloc, CloudSyncState>(
    'SignOutEvent emits [Loading, Authenticated(false)] on success',
    setUp: () {
      when(() => mockSignOut(any())).thenAnswer((_) async => const Right(null));
    },
    build: createBloc,
    act: (bloc) => bloc.add(SignOutEvent()),
    expect: () => [CloudSyncLoading(), const CloudSyncAuthenticated(false)],
  );

  blocTest<CloudSyncBloc, CloudSyncState>(
    'CheckAuthStatusEvent emits [Loading, Error] on failure',
    setUp: () {
      when(
        () => mockCheckAuth(any()),
      ).thenAnswer((_) async => Left(ServerFailure('error')));
    },
    build: createBloc,
    act: (bloc) => bloc.add(CheckAuthStatusEvent()),
    expect: () => [CloudSyncLoading(), isA<CloudSyncError>()],
  );
}
