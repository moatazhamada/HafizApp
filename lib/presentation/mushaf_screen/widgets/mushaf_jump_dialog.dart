import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/quran_index/mushaf_page_index.dart';
import 'package:hafiz_app/core/quran_index/mushaf_types.dart';
import 'package:hafiz_app/core/quran_index/quran_surah.dart';

class MushafJumpDialog extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final MushafType mushafType;
  final int Function(int surahId, MushafType type) surahToPage;

  const MushafJumpDialog({
    super.key,
    required this.currentPage,
    this.totalPages = 604,
    required this.mushafType,
    required this.surahToPage,
  });

  @override
  State<MushafJumpDialog> createState() => _MushafJumpDialogState();
}

class _MushafJumpDialogState extends State<MushafJumpDialog> {
  late int _selectedPage;
  late TextEditingController _pageController;
  String _tab = 'page';

  @override
  void initState() {
    super.initState();
    _selectedPage = widget.currentPage;
    _pageController = TextEditingController(text: _selectedPage.toString());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _buildTab('page', 'lbl_page'.tr),
                const SizedBox(width: 8),
                _buildTab('surah', 'lbl_surah'.tr),
                const SizedBox(width: 8),
                _buildTab('juz', 'lbl_juz'.tr),
              ],
            ),
          ),
          const Divider(height: 24),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTab(String id, String label) {
    final isSelected = _tab == id;
    return GestureDetector(
      onTap: () => setState(() => _tab = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case 'surah':
        return _buildSurahList();
      case 'juz':
        return _buildJuzList();
      default:
        return _buildPagePicker();
    }
  }

  Widget _buildPagePicker() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _pageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'lbl_page_number'.tr,
              hintText: '1 - ${widget.totalPages}',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) => _jumpAndClose(),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _selectedPage.toDouble(),
            min: 1,
            max: widget.totalPages.toDouble(),
            divisions: widget.totalPages - 1,
            label: _selectedPage.toString(),
            onChanged: (value) {
              setState(() {
                _selectedPage = value.toInt();
                _pageController.text = _selectedPage.toString();
              });
            },
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _jumpAndClose, child: Text('lbl_go'.tr)),
        ],
      ),
    );
  }

  Widget _buildSurahList() {
    return ListView.builder(
      itemCount: 114,
      itemBuilder: (context, index) {
        final surah = QuranIndex.quranSurahs[index];
        final page = widget
            .surahToPage(surah.id, widget.mushafType)
            .clamp(1, widget.totalPages);
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        return ListTile(
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              '${surah.id}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          title: Text(
            isArabic ? surah.nameArabic : surah.nameEnglish,
            textDirection: TextDirection.rtl,
          ),
          subtitle: Text('${'lbl_page'.tr} $page'),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => Navigator.pop(context, page),
        );
      },
    );
  }

  Widget _buildJuzList() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juz = index + 1;
        final surahId = MushafPageIndex.getSurahForJuz(juz);
        final page = widget
            .surahToPage(surahId, widget.mushafType)
            .clamp(1, widget.totalPages);
        final isActive = MushafPageIndex.getJuzForPage(_selectedPage) == juz;
        return GestureDetector(
          onTap: () => Navigator.pop(context, page),
          child: Container(
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$juz',
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                Text('p.$page', style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _jumpAndClose() {
    final page = int.tryParse(_pageController.text) ?? _selectedPage;
    Navigator.pop(context, page.clamp(1, widget.totalPages));
  }
}
