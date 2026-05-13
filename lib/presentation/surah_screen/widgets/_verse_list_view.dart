part of '../surah_screen.dart';

class _VerseListView extends StatelessWidget {
  final List<Verse> chapters;
  final BookmarkState bookmarkState;
  final RecitationErrorState errorState;
  final bool isDark;
  final Surah? surah;
  final bool isHifzMode;
  final Set<int> revealedVerses;
  final int? highlightedVerse;
  final bool showTranslation;
  final Map<int, String> translations;
  final Map<int, GlobalKey> verseKeys;
  final Map<int, GlobalKey> richTextVerseKeys;
  final GlobalKey richTextKey;
  final List<VerseRange> currentVerseRanges;
  final void Function(List<VerseRange>) onUpdateVerseRanges;
  final void Function(int verseNumber) onToggleHifzReveal;
  final void Function(Verse aya) onVerifyRecitation;

  const _VerseListView({
    required this.chapters,
    required this.bookmarkState,
    required this.errorState,
    required this.isDark,
    required this.surah,
    required this.isHifzMode,
    required this.revealedVerses,
    required this.highlightedVerse,
    required this.showTranslation,
    required this.translations,
    required this.verseKeys,
    required this.richTextVerseKeys,
    required this.richTextKey,
    required this.currentVerseRanges,
    required this.onUpdateVerseRanges,
    required this.onToggleHifzReveal,
    required this.onVerifyRecitation,
  });

  void _handleShowVerseMenu(
    BuildContext context,
    Verse aya,
    bool isBookmarked,
    bool isRecitationError,
  ) {
    if (surah == null) return;
    showVerseMenu(
      context,
      verse: aya,
      surahId: surah!.id,
      surahNameEnglish: surah!.nameEnglish,
      isBookmarked: isBookmarked,
      isError: isRecitationError,
      onVerifyRecitation: () => onVerifyRecitation(aya),
      onOpenTafsir: () => showTafsirSheet(
        context,
        surahId: surah!.id,
        surahName: surah!.localizedName(context),
        verseNumber: aya.verseNumber,
      ),
      onReadThisAyah: () {
        AudioPlayerHandler().setLoopRange(
          aya.verseNumber - 1,
          aya.verseNumber - 1,
        );
        NavigatorService.pushNamed(
          AppRoutes.audioPlayerScreen,
          arguments: {
            'surahId': surah!.id,
            'surahName': surah!.nameEnglish,
            'startVerse': aya.verseNumber,
          },
        );
      },
      onStartFromHere: () {
        AudioPlayerHandler().clearLoop();
        NavigatorService.pushNamed(
          AppRoutes.audioPlayerScreen,
          arguments: {
            'surahId': surah!.id,
            'surahName': surah!.nameEnglish,
            'startVerse': aya.verseNumber,
          },
        );
      },
    );
  }

  ({Set<int> bookmarkedVerses, Set<int> errorVerses}) _getVerseStates() {
    final surahId = surah?.id ?? -1;
    final bookmarkedVerses = bookmarkState is BookmarkLoaded
        ? (bookmarkState as BookmarkLoaded).bookmarks
              .where((b) => b.surahId == surahId)
              .map((b) => b.verseNumber)
              .toSet()
        : <int>{};
    final errorVerses = errorState is RecitationErrorLoaded
        ? (errorState as RecitationErrorLoaded).errors
              .where((m) => m.surahId == surahId)
              .map((m) => m.verseId)
              .toSet()
        : <int>{};
    return (bookmarkedVerses: bookmarkedVerses, errorVerses: errorVerses);
  }

  @override
  Widget build(BuildContext context) {
    if (PrefUtils().getVerseViewMode()) {
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BismillahWidget(surahId: surah?.id ?? 0),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: _buildSingleLineContentSliver(context),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16.0)),
        ],
      );
    } else {
      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BismillahWidget(surahId: surah?.id ?? 0),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildRichTextContent(context),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRichTextContent(BuildContext context) {
    final colors = AppColors.of(context);
    final textColor = colors.textColor;
    final badgeText = colors.badgeText;

    final verseStates = _getVerseStates();
    final bookmarkedVerseNumbers = verseStates.bookmarkedVerses;
    final errorVerseIds = verseStates.errorVerses;

    List<InlineSpan> spans = [];
    final List<VerseRange> verseRanges = [];
    int currentOffset = 0;

    onUpdateVerseRanges(verseRanges);

    for (var aya in chapters) {
      bool isBookmarked = bookmarkedVerseNumbers.contains(aya.verseNumber);
      bool isRecitationError = errorVerseIds.contains(aya.verseNumber);

      bool isBlurred =
          isHifzMode && !revealedVerses.contains(aya.verseNumber);
      bool isHighlighted = highlightedVerse == aya.verseNumber;

      Color? backgroundColor;
      if (isHighlighted) {
        backgroundColor = colors.highlightBackground;
      } else if (isRecitationError) {
        backgroundColor = colors.errorBackground;
      } else if (isBookmarked) {
        backgroundColor = colors.bookmarkBackground;
      }

      final Color effectiveColor = isBlurred ? Colors.transparent : textColor;
      final List<Shadow>? shadows = isBlurred
          ? [Shadow(color: textColor, blurRadius: 20.0, offset: Offset.zero)]
          : null;

      String verseText = '${aya.arabicText} ';

      if (aya.verseNumber == 1 && surah?.id != 1) {
        const bismillahPrefix = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';
        const bismillahSimple = 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ';
        if (verseText.startsWith(bismillahPrefix)) {
          verseText = verseText.substring(bismillahPrefix.length).trim();
        } else if (verseText.startsWith(bismillahSimple)) {
          verseText = verseText.substring(bismillahSimple.length).trim();
        }
      }

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SizedBox(
            key: richTextVerseKeys.putIfAbsent(
              aya.verseNumber,
              () => GlobalKey(debugLabel: 'verse_anchor_${aya.verseNumber}'),
            ),
            width: 0,
            height: 0,
          ),
        ),
      );
      currentOffset += 1;

      verseRanges.add(
        VerseRange(
          start: currentOffset,
          end: currentOffset + verseText.length,
          verse: aya,
          isBadge: false,
          isBookmarked: isBookmarked,
          isError: isRecitationError,
        ),
      );

      spans.add(
        TextSpan(
          text: '$verseText\u200f',
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: PrefUtils().getQuranFontSize(),
            fontWeight: FontWeight.normal,
            color: effectiveColor,
            backgroundColor: backgroundColor,
            shadows: shadows,
            height: 2.2,
          ),
        ),
      );
      currentOffset += verseText.length + 1;

      final verseMarker =
          ' \u06dd${aya.verseNumber.toLocalizedNumber(context)} ';
      verseRanges.add(
        VerseRange(
          start: currentOffset,
          end: currentOffset + verseMarker.length,
          verse: aya,
          isBadge: true,
          isBookmarked: isBookmarked,
          isError: isRecitationError,
        ),
      );

      spans.add(
        TextSpan(
          text: verseMarker,
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: PrefUtils().getQuranFontSize() - 4,
            fontWeight: FontWeight.bold,
            color: badgeText,
            height: 2.2,
          ),
        ),
      );
      currentOffset += verseMarker.length;

      if (isSajdahVerse(surah?.id ?? 0, aya.verseNumber)) {
        const sajdahMarker = ' \u06de ';
        verseRanges.add(
          VerseRange(
            start: currentOffset,
            end: currentOffset + sajdahMarker.length,
            verse: aya,
            isBookmarked: isBookmarked,
            isError: isRecitationError,
          ),
        );
        spans.add(
          TextSpan(
            text: sajdahMarker,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: PrefUtils().getQuranFontSize() - 4,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
              height: 2.2,
            ),
          ),
        );
        currentOffset += sajdahMarker.length;
      }

      spans.add(const TextSpan(text: '\u200f'));
      currentOffset += 1;

      if (showTranslation && translations[aya.verseNumber] != null) {
        final translationText = translations[aya.verseNumber]!;
        verseRanges.add(
          VerseRange(
            start: currentOffset,
            end: currentOffset + 1,
            verse: aya,
            isBadge: false,
            isBookmarked: isBookmarked,
            isError: isRecitationError,
          ),
        );
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 6.0, bottom: 14.0),
              child: Text(
                translationText,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  height: 1.5,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        );
        currentOffset += 1;
      }
    }

    final textSpan = TextSpan(children: spans);
    onUpdateVerseRanges(verseRanges);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Semantics(
          label: 'lbl_quran_text'.tr,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final range = _findRange(details.localPosition, verseRanges);
              if (range == null) return;

              if (isHifzMode) {
                onToggleHifzReveal(range.verse.verseNumber);
              } else {
                if (surah != null) {
                  PrefUtils().setSurahVerseIndex(
                    surah!.id,
                    range.verse.verseNumber - 1,
                  );
                  PrefUtils().saveLastReadSurah(surah!);
                }
                _handleShowVerseMenu(
                  context,
                  range.verse,
                  range.isBookmarked,
                  range.isError,
                );
              }
            },
            onLongPressStart: (details) {
              if (isHifzMode) {
                final range = _findRange(details.localPosition, verseRanges);
                if (range != null) {
                  _handleShowVerseMenu(
                    context,
                    range.verse,
                    range.isBookmarked,
                    range.isError,
                  );
                }
              }
            },
            child: RichText(
              key: richTextKey,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              text: textSpan,
            ),
          ),
        );
      },
    );
  }

  VerseRange? _findRange(Offset localPosition, List<VerseRange> ranges) {
    final RenderObject? renderObject = richTextKey.currentContext
        ?.findRenderObject();
    if (renderObject is RenderParagraph) {
      final TextPosition position = renderObject.getPositionForOffset(
        localPosition,
      );
      final offset = position.offset;

      for (final range in ranges) {
        if (offset >= range.start && offset < range.end) {
          return range;
        }
      }
    }
    return null;
  }

  Widget _buildSingleLineContentSliver(BuildContext context) {
    final colors = AppColors.of(context);
    final textColor = colors.textColor;
    final badgeBorder = colors.badgeBorder;
    final badgeText = colors.badgeText;
    final badgeGradient = colors.badgeGradient;

    final verseStates = _getVerseStates();
    final bookmarkedVerseNumbers = verseStates.bookmarkedVerses;
    final errorVerseIds = verseStates.errorVerses;

    return SliverList.builder(
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final aya = chapters[index];
        bool isBookmarked = bookmarkedVerseNumbers.contains(aya.verseNumber);
        bool isRecitationError = errorVerseIds.contains(aya.verseNumber);

        bool isBlurred =
            isHifzMode && !revealedVerses.contains(aya.verseNumber);
        bool isHighlighted = highlightedVerse == aya.verseNumber;

        Color? backgroundColor;
        if (isHighlighted) {
          backgroundColor = colors.highlightBackground;
        } else if (isRecitationError) {
          backgroundColor = colors.errorBackground;
        } else if (isBookmarked) {
          backgroundColor = colors.bookmarkBackground;
        }

        String verseText = aya.arabicText;
        if (aya.verseNumber == 1 && surah?.id != 1) {
          const bismillahPrefix = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';
          if (verseText.startsWith(bismillahPrefix)) {
            verseText = verseText.substring(bismillahPrefix.length).trim();
          } else {
            const bismillahSimple = 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ';
            if (verseText.startsWith(bismillahSimple)) {
              verseText = verseText.substring(bismillahSimple.length).trim();
            }
          }
        }

        return Semantics(
          button: true,
          label: '${'lbl_ayah'.tr} ${aya.verseNumber}',
          child: GestureDetector(
            onTap: () {
              if (isHifzMode) {
                onToggleHifzReveal(aya.verseNumber);
              } else {
                if (surah != null) {
                  PrefUtils().setSurahVerseIndex(
                    surah!.id,
                    aya.verseNumber - 1,
                  );
                  PrefUtils().saveLastReadSurah(surah!);
                }
                _handleShowVerseMenu(
                  context,
                  aya,
                  isBookmarked,
                  isRecitationError,
                );
              }
            },
            onLongPress: () {
              if (isHifzMode) {
                _handleShowVerseMenu(
                  context,
                  aya,
                  isBookmarked,
                  isRecitationError,
                );
              }
            },
            child: Container(
              key: verseKeys.putIfAbsent(
                aya.verseNumber,
                () => GlobalKey(debugLabel: 'verse_${aya.verseNumber}'),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: (isBookmarked || isRecitationError || isHighlighted)
                    ? Border.all(
                        color: isHighlighted
                            ? Colors.teal.withValues(alpha: 0.5)
                            : isRecitationError
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.teal.withValues(alpha: 0.3),
                        width: isHighlighted ? 2 : 1,
                      )
                    : null,
              ),
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                textDirection: TextDirection.rtl,
                children: [
                  _HifzModeOverlay(
                    text: verseText,
                    isBlurred: isBlurred,
                    textColor: textColor,
                    baseStyle: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: PrefUtils().getQuranFontSize(),
                      fontWeight: FontWeight.normal,
                      color: textColor,
                      height: 2.2,
                    ),
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                  ),
                  if (isSajdahVerse(surah?.id ?? 0, aya.verseNumber))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Tooltip(
                        message: 'lbl_sajdah'.tr,
                        child: Text(
                          '\u06de',
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: PrefUtils().getQuranFontSize() - 6,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  ExcludeSemantics(
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: badgeGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: badgeBorder, width: 1.2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        aya.verseNumber.toLocalizedNumber(context),
                        style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ),
                  if (showTranslation &&
                      translations[aya.verseNumber] != null)
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                        child: Text(
                          translations[aya.verseNumber]!,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.of(context).textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


extension _SurahScreenStateScroll on _SurahScreenState {
  void _scrollToVerseWithRetry(
    int verseNumber,
    List<Verse> chapters, {
    int attempt = 0,
  }) {
    if (attempt == 0) {
      final route = ModalRoute.of(context);
      if (route is TransitionRoute) {
        final animation = route?.animation;
        if (animation != null &&
            animation.status != AnimationStatus.completed) {
          void handler(AnimationStatus status) {
            if (status == AnimationStatus.completed) {
              animation.removeStatusListener(handler);
              // ignore: invalid_use_of_protected_member
              if (mounted) {
                _scrollToVerseWithRetry(verseNumber, chapters, attempt: 0);
              }
            }
          }

          animation.addStatusListener(handler);
          return;
        }
      }
    }

    if (attempt > 20) return;

    const int delay = 200;

    Future.delayed(const Duration(milliseconds: delay), () {
      // ignore: invalid_use_of_protected_member
      if (!mounted) return;
      bool success = _scrollToVerse(verseNumber, chapters);
      if (!success) {
        _scrollToVerseWithRetry(verseNumber, chapters, attempt: attempt + 1);
      } else {
        Future.delayed(const Duration(seconds: 3), () {
          // ignore: invalid_use_of_protected_member
          if (mounted) _clearHighlight();
        });
      }
    });
  }

  bool _scrollToVerse(int verseNumber, List<Verse> chapters) {
    if (PrefUtils().getVerseViewMode()) {
      final key = _verseKeys[verseNumber];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
        return true;
      }
      return false;
    } else {
      final anchorKey = _richTextVerseKeys[verseNumber];
      if (anchorKey != null && anchorKey.currentContext != null) {
        Scrollable.ensureVisible(
          anchorKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
        return true;
      }

      final RenderObject? renderObject = _richTextKey.currentContext
          ?.findRenderObject();

      if (renderObject is RenderParagraph && _currentVerseRanges.isNotEmpty) {
        final verseRange = _currentVerseRanges.firstWhere(
          (r) => r.verse.verseNumber == verseNumber && !r.isBadge,
          orElse: () => _currentVerseRanges.first,
        );

        try {
          final boxes = renderObject.getBoxesForSelection(
            TextSelection(
              baseOffset: verseRange.start,
              extentOffset: verseRange.start + 1,
            ),
          );

          if (boxes.isNotEmpty && _scrollController.hasClients) {
            final boxTop = boxes.first.top;
            final globalOffset = renderObject.localToGlobal(Offset(0, boxTop));
            final currentScroll = _scrollController.offset;
            const double targetScreenY = 140.0;
            final delta = globalOffset.dy - targetScreenY;
            final targetScroll = (currentScroll + delta).clamp(
              0.0,
              _scrollController.position.maxScrollExtent,
            );

            _scrollController.animateTo(
              targetScroll,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
            return true;
          }
        } catch (e) {
          Logger.warning('Scroll error: $e', feature: 'SurahScreen');
          return false;
        }
      }
      return false;
    }
  }

  void _saveReadingProgress() {
    if (surah == null) return;

    PrefUtils().saveLastReadSurah(surah!);

    int? visibleVerseNumber;

    if (PrefUtils().getVerseViewMode()) {
      for (var entry in _verseKeys.entries) {
        final key = entry.value;
        if (key.currentContext != null) {
          final RenderBox? box =
              key.currentContext!.findRenderObject() as RenderBox?;
          if (box != null) {
            final position = box.localToGlobal(Offset.zero);
            if (position.dy >= 0 &&
                position.dy < MediaQuery.of(context).size.height / 2) {
              visibleVerseNumber = entry.key;
              break;
            }
          }
        }
      }
    } else {
      final RenderObject? renderObject = _richTextKey.currentContext
          ?.findRenderObject();
      if (renderObject is RenderParagraph && _currentVerseRanges.isNotEmpty) {
        try {
          if (_scrollController.hasClients) {
            final Size size = renderObject.size;
            final Offset targetLcOffset = Offset(
              20,
              (20.0).clamp(0.0, (size.height - 1).clamp(0.0, double.infinity)),
            );
            final textPosition = renderObject.getPositionForOffset(
              targetLcOffset,
            );
            final textOffset = textPosition.offset;

            final range = _currentVerseRanges.firstWhere(
              (r) => textOffset >= r.start && textOffset < r.end,
              orElse: () => _currentVerseRanges.first,
            );

            visibleVerseNumber = range.verse.verseNumber;
          }
        } catch (e) {
          Logger.warning('Reading progress save failed: \$e', feature: 'Surah');
        }
      }
    }

    if (visibleVerseNumber != null) {
      PrefUtils().setSurahVerseIndex(surah!.id, visibleVerseNumber - 1);
    }
  }
}
