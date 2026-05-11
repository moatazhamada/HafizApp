import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hafiz_app/domain/usecase/cloud_sync/sync_with_qf.dart';
import 'package:hafiz_app/presentation/cloud_sync/bloc/cloud_sync_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncWithQf extends Mock implements SyncWithQf {}

void main() {
  late MockSyncWithQf mockUseCase;
  late CloudSyncBloc bloc;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockUseCase = MockSyncWithQf();
    bloc = CloudSyncBloc(syncWithQf: mockUseCase);
  });

  tearDown(() => bloc.close());

  test('initial state is CloudSyncInitial', () {
    expect(bloc.state, isA<CloudSyncInitial>());
  });
}
