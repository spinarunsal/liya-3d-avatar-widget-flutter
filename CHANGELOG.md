# Changelog

All notable changes to this project will be documented in this file.

## [0.1.3] - 2026-02-27

### Fixed
- Critical bug: `catchError` callback in audio service missing return value (`body_might_complete_normally_catch_error`)
- Migrated all `withOpacity()` calls to `withValues(alpha:)` (85+ occurrences across 9 files)
- Migrated deprecated `speech_to_text` parameters to `SpeechListenOptions` API
- Replaced deprecated `Matrix4.scale` with `Matrix4.diagonal3Values`

### Removed
- Unused imports (`dart:convert`, `foundation.dart`, `liya3d_enums.dart`, `liya3d_glass_decoration.dart`, `liya3d_colors.dart`)
- Unused fields (`_webViewController`, `_isInitialized`)
- Unused local variable (`screenSize`)
- Dead code methods (`_buildEmptyState`, `_buildChatBubble`, `_buildVoiceControl`)

## [0.1.2] - 2025-02-24

### Fixed
- iOS microphone permission — now requests mic + speech recognition permissions on both Android and iOS
- Added `viewport-fit=cover` to WebView meta tag for iOS safe area support

## [0.1.0] - 2024-02-17

### Added
- Initial public release
- `Liya3dAvatarWidget` - Standalone 3D talking avatar widget
- `Liya3dKioskWidget` - Full-featured kiosk mode with chat interface
- Real-time lip-sync with viseme support
- Voice input/output with speech recognition
- Multi-language support (English, Turkish)
- Liquid glass UI theme
- File attachment support
- Session management
- Idle animations (blinking, breathing, micro-expressions)

### Features
- Three.js powered 3D avatar rendering via WebView
- GLB/GLTF model support with ARKit blendshapes
- Real-time audio streaming with lip-sync
- Customizable colors and themes
- Premium overlay support
- Cross-platform (iOS, Android, Web)
