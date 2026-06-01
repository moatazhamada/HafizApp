import 'package:flutter/material.dart';
import 'reflections_section.dart';
import '../bloc/verse_study_bloc.dart';

class ReflectionsTab extends StatelessWidget {
  final VerseStudyLoaded state;

  const ReflectionsTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ReflectionsSection(
        verseKey: state.verseKey ?? '',
        reflections: state.reflections,
        isLoading: state.reflectionsLoading,
      ),
    );
  }
}
