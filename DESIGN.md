---
name: HafizApp Design System
version: 1.0.0
description: A Quran memorization assistant's design system, emphasizing tranquility, readability, and correct RTL semantics.
colors:
  primary: "#006754"
  primaryDark: "#00332C"
  primaryLight: "#E0F2F1"
  onPrimary: "#FFFFFF"
  accent: "#87D1A4"
  surface: "#FFFFFF"
  surfaceVariant: "#F5F5F5"
  onSurface: "#1A1A1A"
  error: "#D32F2F"
  success: "#4CAF50"
  warning: "#xFFFF9800"
  mushafPageBg: "#FFFBF0"
  mushafPageBorder: "#E8D5B7"
  mushafTextPrimary: "#1A1A1A"
  bismillahColor: "#004B40"
typography:
  headingLarge:
    fontFamily: Poppins
    fontSize: 24px
    fontWeight: 700
  bodyLarge:
    fontFamily: Poppins
    fontSize: 16px
    fontWeight: 400
  quranLarge:
    fontFamily: NotoNaskhArabic
    fontSize: 28px
    fontWeight: 400
    lineHeight: 2.0
rounded:
  sm: 4px
  md: 8px
  lg: 16px
  xl: 24px
  circular: 100px
spacing:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 24px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.onPrimary}"
    rounded: "{rounded.xl}"
    padding: "{spacing.lg}"
  surah-list-item:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.textPrimary}"
    padding: "{spacing.md}"
  continue-reading-card:
    backgroundColor: "{colors.primaryLight}"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
---

## Overview

HafizApp is a non-profit Quran memorization assistant. The UI is designed to be calm, distraction-free, and organic, drawing inspiration from physical Musahif (Quran books).

## Typography

The app uses a dual-font system:
- **Latin/UI Text:** `Poppins` is used for all Latin text, providing a modern, clean, and rounded geometric sans-serif look.
- **Quranic/Arabic Text:** `NotoNaskhArabic` is used for all Quranic verses and Arabic text, ensuring optimal legibility and correct rendering of Arabic diacritics (tashkeel).

## Colors

The color palette is built around "Islamic Green" to inspire focus and tranquility.
- **Primary (`#006754`):** Used for AppBars, core interactive elements, and major emphasis.
- **Accent (`#87D1A4`):** Used for subtle highlights and secondary interactive states.
- **Mushaf Page Background (`#FFFBF0`):** A warm, off-white "paper" color specifically calibrated to reduce eye strain when reading Quranic text for extended periods. Do not use pure white for the reading surface.

## RTL & Navigation Semantics

**CRITICAL RULE:** The Quran is inherently RTL. All Quran/Mushaf content **must** use RTL semantics regardless of the user's overall UI language setting.

1. **Directionality:** All Arabic text must enforce `textDirection: TextDirection.rtl`.
2. **Spatial Navigation:** Navigation icons that imply moving through the Quran (Next, Previous, Chevrons) must adapt to RTL correctly. "Next Surah" is on the left, "Previous Surah" is on the right.
3. **Temporal Exceptions:** Media playback controls (Play, Pause, Fast Forward 10s) represent *time*, not space, and should **not** be flipped.
4. **Mushaf Swiping:** The Mushaf page viewer should use `PageView(reverse: true)` to ensure right-to-left physical swiping behavior.

## Theming

HafizApp fully supports light and dark modes. Ensure that when building components, you use `AppColors.of(context)` to retrieve the current semantic color token rather than hardcoding hex values into widgets. The Mushaf colors shift to a darker, lower-contrast profile in dark mode (e.g., `mushafPageBg` becomes `#2A2420`).
