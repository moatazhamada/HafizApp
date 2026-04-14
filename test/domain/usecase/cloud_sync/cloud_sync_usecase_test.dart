import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/core/usecase/usecase.dart';
import 'package:hafiz_app/domain/repository/cloud_sync_repository.dart';
import 'package:hafiz_app/domain/usecase/cloud_sync/cloud_sync_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockCloudSyncRepository extends Mock implements CloudSyncRepository {}

void main() {
  late MockCloudSyncRepository mockRepository;
  late PerformCloudSync performCloudSync;
  late CheckCloudSyncAuth checkCloudSyncAuth;
  late SignInCloudSync signInCloudSync;
  late SignOutCloudSync signOutCloudSync;

  setUpAll(() {
    registerFallbackValue(SyncDirection.localToRemote);
  });

  setUp(() {
    mockRepository = MockCloudSyncRepository();
    performCloudSync = PerformCloudSync(repository: mockRepository);
    checkCloudSyncAuth = CheckCloudSyncAuth(repository: mockRepository);
    signInCloudSync = SignInCloudSync(repository: mockRepository);
    signOutCloudSync = SignOutCloudSync(repository: mockRepository);

    registerFallbackValue(NoParams());
  });

  group('CheckCloudSyncAuth', () {
    test('returns Right(true) when authenticated', () async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => const Right(true));

      final result = await checkCloudSyncAuth(NoParams());

      expect(result, const Right(true));
      verify(() => mockRepository.isAuthenticated());
    });

    test('returns Right(false) when not authenticated', () async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => const Right(false));

      final result = await checkCloudSyncAuth(NoParams());

      expect(result, const Right(false));
    });

    test('returns Left on failure', () async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => Left(ServerFailure('error')));

      final result = await checkCloudSyncAuth(NoParams());

      expect(result.isLeft(), isTrue);
    });
  });

  group('SignInCloudSync', () {
    test('returns Right on success', () async {
      when(
        () => mockRepository.signInAnonymously(),
      ).thenAnswer((_) async => const Right(null));

      final result = await signInCloudSync(NoParams());

      expect(result, const Right(null));
      verify(() => mockRepository.signInAnonymously());
    });

    test('returns Left on failure', () async {
      when(
        () => mockRepository.signInAnonymously(),
      ).thenAnswer((_) async => Left(ServerFailure('error')));

      final result = await signInCloudSync(NoParams());

      expect(result.isLeft(), isTrue);
    });
  });

  group('SignOutCloudSync', () {
    test('returns Right on success', () async {
      when(
        () => mockRepository.signOut(),
      ).thenAnswer((_) async => const Right(null));

      final result = await signOutCloudSync(NoParams());

      expect(result, const Right(null));
      verify(() => mockRepository.signOut());
    });

    test('returns Left on failure', () async {
      when(
        () => mockRepository.signOut(),
      ).thenAnswer((_) async => Left(ServerFailure('error')));

      final result = await signOutCloudSync(NoParams());

      expect(result.isLeft(), isTrue);
    });
  });

  group('PerformCloudSync', () {
    test('syncs when already authenticated', () async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => const Right(true));
      when(
        () => mockRepository.getCurrentUserId(),
      ).thenAnswer((_) async => const Right('user123'));
      when(
        () => mockRepository.performFullSync(
          any(),
          direction: any(named: 'direction'),
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await performCloudSync(
        const ParamsCloudSync(direction: SyncDirection.localToRemote),
      );

      expect(result, const Right(null));
      verify(
        () => mockRepository.performFullSync(
          'user123',
          direction: SyncDirection.localToRemote,
        ),
      );
    });

    test('signs in and syncs when not authenticated', () async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => const Right(false));
      when(
        () => mockRepository.signInAnonymously(),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockRepository.getCurrentUserId(),
      ).thenAnswer((_) async => const Right('user456'));
      when(
        () => mockRepository.performFullSync(
          any(),
          direction: any(named: 'direction'),
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await performCloudSync(
        const ParamsCloudSync(direction: SyncDirection.bidirectional),
      );

      expect(result, const Right(null));
      verify(() => mockRepository.signInAnonymously());
      verify(
        () => mockRepository.performFullSync(
          'user456',
          direction: SyncDirection.bidirectional,
        ),
      );
    });

    test('returns Left when auth check fails', () async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => Left(ServerFailure('auth error')));

      final result = await performCloudSync(
        const ParamsCloudSync(direction: SyncDirection.localToRemote),
      );

      expect(result.isLeft(), isTrue);
    });

    test('returns Left when userId is null after sign in', () async {
      when(
        () => mockRepository.isAuthenticated(),
      ).thenAnswer((_) async => const Right(false));
      when(
        () => mockRepository.signInAnonymously(),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockRepository.getCurrentUserId(),
      ).thenAnswer((_) async => const Right(null));

      final result = await performCloudSync(
        const ParamsCloudSync(direction: SyncDirection.localToRemote),
      );

      expect(result.isLeft(), isTrue);
    });
  });
}
