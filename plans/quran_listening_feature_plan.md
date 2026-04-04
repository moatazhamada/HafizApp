# Quran Listening Feature - Inline Audio Player Plan

## Problem Statement

The current Quran listening feature has the following issues:
1. **Navigation Issue**: When users activate the audio feature, they are navigated to a separate `AudioPlayerScreen` page instead of staying on the current page (SurahScreen or MushafScreen)
2. **Missing Auto-scroll**: The current verse is not automatically highlighted/scrolled to during playback

## Requirements

1. **Stay on Current Page**: Audio should play on the same page where user initiated it without navigation away
2. **Auto-scroll/Highlight**: Update the scroll position and highlight the current ayah while the audio is playing
3. **Verse Change Dialog**: When user selects a different ayah while sound is playing, show a dialog asking if they want to jump to it

## Current Implementation Analysis

### Existing Components:
- `lib/presentation/audio_player/audio_player_screen.dart` - Full page audio player
- `lib/presentation/surah_screen/sheikh_audio_coach_sheet.dart` - Bottom sheet for verse coaching
- `lib/presentation/surah_screen/surah_screen.dart` - Surah reading screen
- `lib/presentation/mushaf_screen/mushaf_screen.dart` - Mushaf (Quran pages) reading screen
- `lib/core/audio/audio_player_handler.dart` - Audio service handler
- `lib/routes/app_routes.dart` - Navigation routes

### Current Flow:
```
User taps listen button → AppRoutes.goToAudioPlayer() → Navigator.push(AudioPlayerScreen)
```

## Solution Architecture

### New Architecture
```mermaid
graph TD
    A[User taps listen button] --> B[Show Inline Audio Player Widget]
    B --> C[Stay on SurahScreen/MushafScreen]
    C --> D[Audio plays continuously]
    D --> E[Update current verse highlight]
    E --> F[Auto-scroll to current verse]
    F --> G{User taps different verse?}
    G -->|Yes| H[Show confirmation dialog]
    H --> I[Jump to selected verse}
```

### Component Structure

1. **InlineAudioPlayer Widget** (New)
   - Location: `lib/presentation/widgets/inline_audio_player.dart`
   - Reusable widget that can be embedded in both SurahScreen and MushafScreen
   - Contains: Play/Pause, Progress, Speed control, Current verse info

2. **AudioStateNotifier** (New)
   - Location: `lib/core/audio/audio_state_notifier.dart`
   - State management for audio playback across screens
   - Provides: currentVerse, isPlaying, playbackPosition

3. **Modified SurahScreen**
   - Add InlineAudioPlayer widget at bottom
   - Subscribe to AudioStateNotifier for verse updates
   - Auto-scroll to current verse

4. **Modified MushafScreen**
   - Add InlineAudioPlayer widget at bottom
   - Subscribe to AudioStateNotifier for verse updates
   - Auto-scroll to current page/verse

## Implementation Steps

### Step 1: Create AudioStateNotifier
- Create state management for audio playback
- Manage current verse, playback state, position
- Provide stream for verse changes

### Step 2: Create InlineAudioPlayer Widget
- Reusable player UI component
- Play/Pause, Skip next/prev, Speed control
- Current verse display
- Collapsible/expandable design

### Step 3: Modify SurahScreen
- Replace navigation to AudioPlayerScreen with InlineAudioPlayer
- Add auto-scroll logic when verse changes
- Add verse tap handler with confirmation dialog

### Step 4: Modify MushafScreen
- Same changes as SurahScreen adapted for page-based navigation

### Step 5: Implement Verse Change Dialog
- Show dialog when user taps different verse during playback
- Options: "Jump to verse" or "Cancel"
- Update audio position to selected verse

## File Changes Summary

### New Files:
1. `lib/presentation/widgets/inline_audio_player.dart` - Inline audio player widget
2. `lib/core/audio/audio_state_notifier.dart` - Audio state management

### Modified Files:
1. `lib/routes/app_routes.dart` - Update navigation or keep for backward compatibility
2. `lib/presentation/surah_screen/surah_screen.dart` - Embed inline player
3. `lib/presentation/mushaf_screen/mushaf_screen.dart` - Embed inline player

### Optional (for mini-player mode):
- `lib/presentation/widgets/audio_mini_player.dart` - Draggable mini player overlay

## UI Options for Inline Audio Player

### Option 1: Bottom Sheet Player (Recommended for this task)
- Player appears as a collapsible panel at the bottom of the screen
- Expands to show full controls when tapped
- Keeps user on current page while reading
- Easy to implement and familiar UX

**Implementation:**
- Use `DraggableScrollableSheet` or custom `AnimatedContainer`
- Collapsed: Show mini player with play/pause, verse number, and expand icon
- Expanded: Show full controls with progress bar, speed, skip buttons

```dart
// Bottom Sheet Player Structure
Widget build(BuildContext context) {
  return DraggableScrollableSheet(
    initialChildSize: 0.1,  // Collapsed height
    minChildSize: 0.1,
    maxChildSize: 0.5,     // Expanded height
    builder: (context, scrollController) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: _isExpanded ? _buildExpandedPlayer() : _buildMiniPlayer(),
      );
    },
  );
}
```

### Option 2: Floating Mini Player
- Small player overlay that floats above content
- Can be dragged and positioned by user
- Doesn't take up screen space when collapsed
- More complex to implement

### Option 3: Fixed Bottom Bar
- Player always visible at bottom of screen
- Takes consistent space (approx 60-80px)
- Simplest implementation
- May reduce reading space

## Feature Comparison

| Feature | Bottom Sheet | Floating | Fixed Bar |
|---------|-------------|----------|-----------|
| User stays on page | ✅ | ✅ | ✅ |
| Auto-scroll to verse | ✅ | ✅ | ✅ |
| Collapsible | ✅ | ✅ | ❌ |
| Draggable | ❌ | ✅ | ❌ |
| Easy implementation | ✅ | ❌ | ✅ |

## Selected Approach

For this task, **Option 1 (Bottom Sheet Player)** is recommended as it:
1. Keeps users on the current page
2. Provides familiar mobile UX
3. Allows expanding for full controls
4. Doesn't permanently reduce reading space
