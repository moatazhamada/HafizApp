import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/data/model/bookmark.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  late List<Bookmark> _bookmarks;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  void _loadBookmarks() {
    setState(() {
      _bookmarks = PrefUtils().getBookmarks();
    });
  }

  void _removeBookmark(Bookmark bookmark) {
    setState(() {
      PrefUtils().removeBookmark(bookmark);
      _loadBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _bookmarks.isEmpty
          ? const Center(
              child: Text('No bookmarks yet.'),
            )
          : ListView.builder(
              itemCount: _bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = _bookmarks[index];
                return ListTile(
                  title: Text(bookmark.surahName),
                  subtitle: Text(bookmark.text),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeBookmark(bookmark),
                  ),
                );
              },
            ),
    );
  }
}
