# Fix Navigation Drawer Bugs

## Problem Statement
Both navigation drawers are not accessible in the app:
1. Main navigation drawer (AdaptiveNavigationShell) - missing hamburger icon
2. Surah screen drawer - not opening properly

## Root Cause Analysis

### Issue 1: Main Navigation Drawer Missing Hamburger Icon
**Location**: `lib/widgets/adaptive_navigation_shell.dart`
**Problem**: The phone layout (lines 191-197) has a drawer but no hamburger icon to open it:
```dart
// Phone: NavigationDrawer layout
return Scaffold(
  drawer: _buildDrawer(theme),
  body: IndexedStack(index: _selectedIndex, children: _destinations),
);
```
**Fix Needed**: Add a hamburger menu button (or EndDrawer) to open the drawer, OR add a leading widget that can trigger `Scaffold.of(context).openDrawer()`.

### Issue 2: Surah Screen Drawer Not Accessible
**Location**: `lib/presentation/surah_screen/surah_screen.dart`, lines 919-937
**Problem**: The hamburger icon is only shown when `!canPop && _isPhoneLayout(context)`. The `_isPhoneLayout` check may not be working correctly, OR the drawer is behind the IndexedStack content.

## Proposed Fixes

### Fix 1: Add Hamburger Icon to Main Navigation Shell
Modify `lib/widgets/adaptive_navigation_shell.dart`:
- For phone layout, wrap the body in a Builder to access Scaffold
- Add a leading IconButton with hamburger icon that opens drawer

### Fix 2: Ensure Surah Screen Drawer Works
- Verify `_isPhoneLayout(context)` is returning correct value
- Ensure drawer is properly attached and accessible
- Consider using `drawerEdgeGestureWidth` or ensure gesture works

## Files to Modify
1. `lib/widgets/adaptive_navigation_shell.dart` - Add hamburger icon
2. `lib/presentation/surah_screen/surah_screen.dart` - Debug/fix drawer access

## Success Criteria
- [ ] Hamburger menu opens main navigation drawer on phone
- [ ] Surah screen shows hamburger when no back stack on phone
