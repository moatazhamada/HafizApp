import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/analytics/analytics_helper.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/utils/image_constant.dart';
import 'package:hafiz_app/domain/entities/verse.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/presentation/bookmarks/bloc/bookmark_bloc.dart';
import 'package:hafiz_app/presentation/recitation_error/bloc/recitation_error_bloc.dart';
import 'package:hafiz_app/presentation/surah_screen/bloc/surah_bloc.dart';
import 'package:hafiz_app/presentation/surah_screen/surah_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:audio_service/audio_service.dart';
import 'package:hafiz_app/core/audio/audio_player_handler.dart';
import 'package:rxdart/rxdart.dart';

import '../../utils/test_app_widget.dart';

class MockSurahBloc extends MockBloc<SurahEvent, SurahState>
    implements SurahBloc {}

class MockBookmarkBloc extends MockBloc<BookmarkEvent, BookmarkState>
    implements BookmarkBloc {}

class MockRecitationErrorBloc
    extends MockBloc<RecitationErrorEvent, RecitationErrorState>
    implements RecitationErrorBloc {}

class MockAnalyticsHelper extends Mock implements AnalyticsHelper {}

class MockAudioPlayerHandler extends Mock implements AudioPlayerHandler {}

void main() {
  late MockSurahBloc mockSurahBloc;
  late MockBookmarkBloc mockBookmarkBloc;
  late MockRecitationErrorBloc mockRecitationErrorBloc;
  late MockAnalyticsHelper mockAnalyticsHelper;
  late MockAudioPlayerHandler mockAudioPlayerHandler;

  setUpAll(() async {
    await setupTestDependencies();
    registerFallbackValue(Surah(1, 'Test', 'Test'));
    registerFallbackValue(const LoadSurahEvent(surahId: '1'));
    registerFallbackValue(LoadingSurahState());

    // Bypass SVG errors by pointing to a mock PNG that actually exists
    ImageConstant.imgQuranOnboarding = ImageConstant.imgBismillah;
    ImageConstant.imgLastReadBg = ImageConstant.imgBismillah;
    ImageConstant.imgGroupCircles = ImageConstant.imgBismillah;
  });

  setUp(() {
    mockSurahBloc = MockSurahBloc();
    mockBookmarkBloc = MockBookmarkBloc();
    mockRecitationErrorBloc = MockRecitationErrorBloc();
    mockAnalyticsHelper = MockAnalyticsHelper();
    mockAudioPlayerHandler = MockAudioPlayerHandler();

    setupStrictOverflowHandler();

    // Mock initial states and streams
    when(() => mockSurahBloc.state).thenReturn(LoadingSurahState());
    // Stream mocking removed to allow mock's default behavior
    // This ensures tests catch stream-related bugs
    when(() => mockBookmarkBloc.state).thenReturn(const BookmarkLoaded([]));
    when(
      () => mockRecitationErrorBloc.state,
    ).thenReturn(const RecitationErrorLoaded([]));

    // Mock AnalyticsHelper
    when(
      () => mockAnalyticsHelper.logSurahOpened(any(), any()),
    ).thenAnswer((_) async {});

    // Mock audio handler playback state to keep mini player stable
    final playbackSubject = BehaviorSubject.seeded(PlaybackState());
    when(
      () => mockAudioPlayerHandler.playbackState,
    ).thenAnswer((_) => playbackSubject);

    // Add teardown to close the stream
    addTearDown(() {
      playbackSubject.close();
    });

    // Register blocs
    if (sl.isRegistered<SurahBloc>()) sl.unregister<SurahBloc>();
    sl.registerFactory<SurahBloc>(() => mockSurahBloc);

    if (sl.isRegistered<AnalyticsHelper>()) sl.unregister<AnalyticsHelper>();
    sl.registerLazySingleton<AnalyticsHelper>(() => mockAnalyticsHelper);

    if (sl.isRegistered<AudioPlayerHandler>()) {
      sl.unregister<AudioPlayerHandler>();
    }
    sl.registerLazySingleton<AudioPlayerHandler>(() => mockAudioPlayerHandler);
  });

  Widget createWidgetUnderTest({Size screenSize = const Size(360, 800)}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BookmarkBloc>.value(value: mockBookmarkBloc),
        BlocProvider<RecitationErrorBloc>.value(value: mockRecitationErrorBloc),
      ],
      child: mountTestWidget(
        Navigator(
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              settings: RouteSettings(
                name: '/surah_screen',
                arguments: {'surah': Surah(1, 'Test', 'Test')},
              ),
              builder: (context) => const SurahScreen(),
            );
          },
        ),
        screenSize: screenSize,
      ),
    );
  }

  group('SurahScreen UI Tests', () {
    testWidgets('renders skeleton loader when state is LoadingSurahState', (
      WidgetTester tester,
    ) async {
      when(() => mockSurahBloc.state).thenReturn(LoadingSurahState());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders surah content when state is SuccessSurahState', (
      WidgetTester tester,
    ) async {
      final List<Verse> chapters = [
        const Verse(chapterId: 1, verseNumber: 1, text: 'Bismillah'),
      ];

      when(
        () => mockSurahBloc.state,
      ).thenReturn(SuccessSurahState(chapters: chapters));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.textContaining('Test'), findsWidgets);
    });

    testWidgets('renders layout correctly in landscape without overflows', (
      WidgetTester tester,
    ) async {
      when(() => mockSurahBloc.state).thenReturn(LoadingSurahState());
      await tester.pumpWidget(
        createWidgetUnderTest(screenSize: const Size(800, 360)),
      );
      await tester.pump();
    });
  });
}
