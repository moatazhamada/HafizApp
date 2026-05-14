import 'package:flutter/material.dart';

// --------------------------------------------------------------------------
// RTL Policy for Hafiz — The Default is RTL
// --------------------------------------------------------------------------
// This is a Quran app. The Quran is Arabic and reads right-to-left.
// Therefore:
//   1. All Quran content (Mushaf, Surah, verse text) is ALWAYS RTL.
//   2. Non-Quran UI (settings, onboarding) follows the app's locale.
//   3. Directional icons MUST adapt to the active text direction.
//   4. Never hardcode TextDirection.ltr on Quran components.
//   5. Prefer AlignmentDirectional, EdgeInsetsDirectional, TextAlign.start/end.
// --------------------------------------------------------------------------

/// Whether the given [context] is in RTL mode.
///
/// This is the single source of truth for RTL checks. Use it everywhere
/// instead of repeating `Directionality.of(context) == TextDirection.rtl`.
bool isRtl(BuildContext context) {
  return Directionality.of(context) == TextDirection.rtl;
}

/// Whether the given [context] is in LTR mode.
bool isLtr(BuildContext context) {
  return Directionality.of(context) == TextDirection.ltr;
}

// ── Directional Icons ──

/// Returns [Icons.arrow_back]. This icon natively supports [matchTextDirection] 
/// and will automatically mirror in RTL contexts (pointing right).
IconData rtlBackArrow(BuildContext context) {
  return Icons.arrow_back;
}

/// Returns [Icons.arrow_forward]. This icon natively supports [matchTextDirection]
/// and will automatically mirror in RTL contexts (pointing left).
IconData rtlForwardArrow(BuildContext context) {
  return Icons.arrow_forward;
}

/// Returns [Icons.chevron_right]. This icon natively supports [matchTextDirection]
/// and will automatically mirror in RTL contexts (pointing left).
///
/// Use this for list-tile trailing chevrons, navigation indicators,
/// and any "proceed to next screen" affordance.
IconData rtlChevron(BuildContext context) {
  return Icons.chevron_right;
}

/// Returns [Icons.arrow_forward_ios_rounded]. This icon natively supports [matchTextDirection]
/// and will automatically mirror in RTL contexts (pointing left).
IconData rtlForwardArrowIos(BuildContext context) {
  return Icons.arrow_forward_ios_rounded;
}

/// Returns [Icons.arrow_forward_rounded]. This icon natively supports [matchTextDirection]
/// and will automatically mirror in RTL contexts (pointing left).
IconData rtlForwardArrowRounded(BuildContext context) {
  return Icons.arrow_forward_rounded;
}

// ── Quran-Specific Icons (always RTL semantics) ──

/// Previous-verse icon for the audio player.
///
/// In LTR: `skip_previous` (points left = back in time).
/// In RTL: horizontally flipped so it points right, matching Arabic
/// spatial thinking where "previous" content lies to the right.
Widget rtlSkipPreviousIcon(BuildContext context, {double size = 24}) {
  final icon = Icon(Icons.skip_previous, size: size);
  if (isLtr(context)) return icon;
  return Transform.flip(flipX: true, child: icon);
}

/// Next-verse icon for the audio player.
///
/// In LTR: `skip_next` (points right = forward in time).
/// In RTL: horizontally flipped so it points left, matching Arabic
/// spatial thinking where "next" content lies to the left.
Widget rtlSkipNextIcon(BuildContext context, {double size = 24}) {
  final icon = Icon(Icons.skip_next, size: size);
  if (isLtr(context)) return icon;
  return Transform.flip(flipX: true, child: icon);
}

// ─-- Alignment & Inset Helpers ──

/// Returns [AlignmentDirectional.centerStart] or [AlignmentDirectional.centerEnd]
/// based on whether the current context is RTL.
///
/// Use this for dismissible backgrounds, action buttons, or any widget
/// that should be visually anchored to the start/end edge.
AlignmentDirectional rtlCenterStart(BuildContext context) {
  return isRtl(context)
      ? AlignmentDirectional.centerEnd
      : AlignmentDirectional.centerStart;
}

/// Returns [AlignmentDirectional.centerEnd] or [AlignmentDirectional.centerStart]
/// based on whether the current context is RTL.
AlignmentDirectional rtlCenterEnd(BuildContext context) {
  return isRtl(context)
      ? AlignmentDirectional.centerStart
      : AlignmentDirectional.centerEnd;
}

/// A convenient edge inset that respects text direction.
///
/// In LTR: start = left, end = right.
/// In RTL: start = right, end = left.
EdgeInsetsDirectional rtlHorizontalInsets(
  BuildContext context, {
  double start = 0,
  double end = 0,
  double top = 0,
  double bottom = 0,
}) {
  return EdgeInsetsDirectional.fromSTEB(start, top, end, bottom);
}
