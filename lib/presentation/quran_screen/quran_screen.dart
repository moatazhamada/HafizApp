import 'package:flutter/material.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';
import 'package:hafiz_app/injection_container.dart';
import 'package:hafiz_app/presentation/home_screen/bloc/home_bloc.dart';
import 'package:hafiz_app/presentation/home_screen/home_screen.dart';

import '../../core/app_export.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final homeBloc = sl<HomeBloc>();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const PageStorageKey('home-list'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: QuranIndex.quranSurahs.length,
      itemBuilder: (context, index) {
        final surah = QuranIndex.quranSurahs[index];
        return InkWell(
          onTap: () {
            PrefUtils().saveLastReadSurah(surah);
            homeBloc.add(HomeShowLastSurahEvent());
            NavigatorService.pushNamed(AppRoutes.surahPage, arguments: surah);
          },
          child: SurahListItem(
            surahId: surah.id,
            nameEnglish: surah.nameEnglish,
            nameArabic: surah.nameArabic,
          ),
        );
      },
    );
  }
}
