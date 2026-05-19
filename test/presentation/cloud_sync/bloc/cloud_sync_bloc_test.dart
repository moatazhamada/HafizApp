import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hafiz_app/core/errors/failures.dart';
import 'package:hafiz_app/domain/usecase/cloud_sync/sync_with_qf.dart';
import 'package:hafiz_app/core/usecase/usecase.dart';
import 'package:hafiz_app/presentation/cloud_sync/bloc/cloud_sync_bloc.dart';

class MockSyncWithQf extends Mock implements SyncWithQf {}

void main() {
  late MockSyncWithQf mockUseCase;

  setUpAll(() {
    registerFallbackValue(NoParams());
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockUseCase = MockSyncWithQf();
  });

  test('initial state is CloudSyncInitial', () {
    final bloc = CloudSyncBloc(syncWithQf: mockUseCase);
    expect(bloc.state, isA<CloudSyncInitial>());
    bloc.close();
  });

  test('SyncWithQf use case returns failure as Left', () async {
    when(() => mockUseCase(any()))
        .thenAnswer((_) async => const Left(ServerFailure('test error')));

    final result = await mockUseCase(NoParams());
    expect(result.isLeft(), isTrue);
  });

  test('SyncWithQf use case returns success as Right', () async {
    when(() => mockUseCase(any()))
        .thenAnswer((_) async => const Right(QfSyncResult(pushed: 5, pulled: 3)));

    final result = await mockUseCase(NoParams());
    result.fold(
      (_) => fail('Expected Right'),
      (syncResult) {
        expect(syncResult.pushed, 5);
        expect(syncResult.pulled, 3);
      },
    );
  });
}
