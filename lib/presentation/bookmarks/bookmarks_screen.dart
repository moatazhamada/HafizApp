import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../injection_container.dart';
import 'bloc/bookmark_bloc.dart';
import '../../widgets/custom_app_bar.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<BookmarkBloc>()..add(LoadBookmarksEvent()),
      child: Scaffold(
        appBar: CustomAppBar(
          height: 60,
          leadingWidth: 40,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              NavigatorService.goBack();
            },
          ),
          centerTitle: true,
          title: Text(
            "Bookmarks",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        body: BlocBuilder<BookmarkBloc, BookmarkState>(
          builder: (context, state) {
            if (state is BookmarkLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is BookmarkLoaded) {
              if (state.bookmarks.isEmpty) {
                return const Center(child: Text("No bookmarks yet."));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.bookmarks.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final bookmark = state.bookmarks[index];
                  return Dismissible(
                    key: Key('${bookmark.surahId}_${bookmark.verseId}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      context.read<BookmarkBloc>().add(
                        RemoveBookmarkEvent(bookmark.surahId, bookmark.verseId),
                      );
                    },
                    child: Card(
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(
                          Icons.bookmark,
                          color: Color(0xFF006754),
                        ),
                        title: Text(
                          bookmark.surahName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          "Verse ${bookmark.verseId} • ${bookmark.createdAt.toString().split(' ')[0]}",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navigate to Surah Screen
                          NavigatorService.pushNamed(
                            AppRoutes.surahPage,
                            arguments: {
                              'surah': QuranIndex.quranSurahs.firstWhere(
                                (e) => e.id == bookmark.surahId,
                              ),
                              'verseIndex': bookmark.verseId - 1,
                              'resume': true,
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            } else if (state is BookmarkError) {
              return Center(child: Text("Error: ${state.message}"));
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
