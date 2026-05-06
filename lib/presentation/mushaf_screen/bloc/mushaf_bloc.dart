import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hafiz_app/core/mushaf/mushaf_page_verse_map.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/core/utils/pref_utils.dart';
import 'mushaf_event.dart';
import 'mushaf_state.dart';

class MushafBloc extends Bloc<MushafEvent, MushafState> {
  bool dualPageEnabled;

  MushafBloc({
    bool? initialDualPage,
  }) : dualPageEnabled = initialDualPage ?? PrefUtils().getMushafDualPage(),
       super(const MushafInitial()) {
    on<LoadPage>(_onLoadPage);
    on<NavigateToPage>(_onNavigateToPage);
    on<ToggleDualPage>(_onToggleDualPage);
  }

  Future<void> _onLoadPage(LoadPage event, Emitter<MushafState> emit) async {
    emit(MushafPageLoading(event.pageNumber));
    try {
      final mushafType = PrefUtils().getMushafType() ?? 'madani';
      final isWarsh = mushafType == 'warsh';

      final ranges = MushafPageVerseMap.getVersesForPage(event.pageNumber);
      if (ranges.isEmpty) {
        emit(MushafPageError(event.pageNumber, 'No verses for this page'));
        return;
      }

      final entries = <AyahEntry>[];

      for (final range in ranges) {
        if (range.surahId < 1 || range.surahId > 114) continue;

        final surah = QuranIndex.quranSurahs[range.surahId - 1];
        final isSurahStart = range.startVerse == 1;

        if (isSurahStart) {
          final isFatiha = range.surahId == 1;
          final isTawbah = range.surahId == 9;
          final showBismillah = isWarsh ? isFatiha : !isFatiha && !isTawbah;

          entries.add(AyahEntry(
            surahId: range.surahId,
            verseNumber: 0,
            surahNameArabic: surah.nameArabic,
            isSurahHeader: true,
            showBismillah: showBismillah,
          ));
        }

        for (int v = range.startVerse; v <= range.endVerse; v++) {
          entries.add(AyahEntry(
            surahId: range.surahId,
            verseNumber: v,
            surahNameArabic: surah.nameArabic,
          ));
        }
      }

      if (entries.isEmpty) {
        emit(MushafPageError(event.pageNumber, 'No entries for this page'));
        return;
      }

      emit(MushafPageLoaded(
        pageNumber: event.pageNumber,
        entries: entries,
        mushafType: mushafType,
      ));
    } catch (e) {
      emit(MushafPageError(event.pageNumber, e.toString()));
    }
  }

  void _onNavigateToPage(NavigateToPage event, Emitter<MushafState> emit) {
    add(LoadPage(event.pageNumber));
  }

  void _onToggleDualPage(ToggleDualPage event, Emitter<MushafState> emit) {
    dualPageEnabled = !dualPageEnabled;
    PrefUtils().setMushafDualPage(dualPageEnabled);
    emit(MushafDualPageToggled(dualPageEnabled));
  }
}
