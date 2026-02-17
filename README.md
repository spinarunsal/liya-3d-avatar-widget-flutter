# Liya 3D Avatar Widget for Flutter

A Flutter package that provides a 3D talking AI avatar widget with real-time lip-sync, voice input/output, and chat capabilities. Built with WebView + Three.js for high-quality 3D rendering.

[![pub.dev](https://img.shields.io/pub/v/liya_3d_avatar_widget_flutter.svg)](https://pub.dev/packages/liya_3d_avatar_widget_flutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 🎭 **3D Avatar** — High-quality 3D avatar with Ready Player Me support
- 👄 **Real-time Lip-sync** — Viseme-based lip synchronization
- 🎤 **Voice Input** — Speech-to-text with native microphone support
- 🔊 **Voice Output** — Text-to-speech with natural voices
- 💬 **Full Chat** — Complete chat interface with message history
- 📎 **File Upload** — Attach files to messages
- 🎨 **Customizable Theme** — Match your app's design
- 📱 **3 Widget Modes** — Standard, Modal Kiosk, Full Kiosk

## Screenshots

<!-- Add screenshots here -->

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  liya_3d_avatar_widget_flutter: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Platform Setup

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <!-- Internet permission -->
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <!-- Microphone permission (for voice input) -->
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    
    <!-- For file picker -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    
    <application
        android:usesCleartextTraffic="true"
        ...>
    </application>
</manifest>
```

Set minimum SDK version in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for voice input</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>This app needs speech recognition for voice commands</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access for file uploads</string>
```

## Quick Start

### Basic Usage

```dart
import 'package:liya_3d_avatar_widget_flutter/liya_3d_avatar_widget_flutter.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: LiyaAvatarWidget(
          apiUrl: 'https://app-X-ai.liyalabs.com', // Your assigned backend URL (see GAR section)
          apiKey: 'your_api_key',
          assistantId: 'your_assistant_id',
        ),
      ),
    );
  }
}
```

### Kiosk Mode (Full Screen)

```dart
LiyaAvatarWidget(
  apiUrl: 'https://app-X-ai.liyalabs.com', // Your assigned backend URL (see GAR section)
  apiKey: 'your_api_key',
  assistantId: 'your_assistant_id',
  widgetMode: LiyaWidgetMode.kiosk,
  assistantName: 'Liya AI',
  welcomeMessage: 'Merhaba! Size nasıl yardımcı olabilirim?',
)
```

### Modal Mode

```dart
// Show as modal dialog
LiyaAvatarWidget.showModal(
  context: context,
  apiUrl: 'https://app-X-ai.liyalabs.com', // Your assigned backend URL (see GAR section)
  apiKey: 'your_api_key',
  assistantId: 'your_assistant_id',
);
```

## Widget Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `apiUrl` | `String` | ✅ | - | Backend API URL |
| `apiKey` | `String` | ✅ | - | API key for authentication |
| `assistantId` | `String` | ✅ | - | Assistant UUID |
| `assistantName` | `String` | ❌ | `'Liya AI'` | Display name for the assistant |
| `widgetMode` | `LiyaWidgetMode` | ❌ | `standard` | Widget display mode |
| `welcomeMessage` | `String` | ❌ | `null` | Initial greeting message |
| `avatarModelUrl` | `String` | ❌ | `null` | Custom avatar GLB model URL |
| `theme` | `LiyaTheme` | ❌ | `null` | Custom theme configuration |
| `enableVoice` | `bool` | ❌ | `true` | Enable voice input/output |
| `enableFileUpload` | `bool` | ❌ | `true` | Enable file attachments |
| `showSuggestions` | `bool` | ❌ | `true` | Show suggestion chips |
| `suggestions` | `List<String>` | ❌ | `[]` | Custom suggestion texts |
| `onMessageSent` | `Function` | ❌ | `null` | Callback when user sends message |
| `onMessageReceived` | `Function` | ❌ | `null` | Callback when AI responds |
| `onError` | `Function` | ❌ | `null` | Error callback |
| `onAvatarLoaded` | `Function` | ❌ | `null` | Called when avatar model loads |

## Widget Modes

### `LiyaWidgetMode.standard`
Default mode with avatar and chat panel side by side.

### `LiyaWidgetMode.modalKiosk`
Full-screen modal overlay, ideal for temporary interactions.

### `LiyaWidgetMode.kiosk`
Full-screen embedded mode, perfect for kiosk applications.

```dart
enum LiyaWidgetMode {
  standard,
  modalKiosk,
  kiosk,
}
```

## Theme Customization

```dart
LiyaAvatarWidget(
  // ... required params
  theme: LiyaTheme(
    primaryColor: Color(0xFF6366F1),
    backgroundColor: Color(0xFF1A1A2E),
    surfaceColor: Color(0xFF16213E),
    textColor: Colors.white,
    mutedTextColor: Colors.white70,
    borderRadius: 16.0,
    fontFamily: 'Inter',
  ),
)
```

### LiyaTheme Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `primaryColor` | `Color` | `#6366F1` | Primary accent color |
| `backgroundColor` | `Color` | `#1A1A2E` | Main background color |
| `surfaceColor` | `Color` | `#16213E` | Card/surface background |
| `textColor` | `Color` | `white` | Primary text color |
| `mutedTextColor` | `Color` | `white70` | Secondary text color |
| `borderRadius` | `double` | `16.0` | Border radius for cards |
| `fontFamily` | `String` | `null` | Custom font family |

## Callbacks

```dart
LiyaAvatarWidget(
  // ... required params
  onMessageSent: (String message, List<File>? files) {
    print('User sent: $message');
  },
  onMessageReceived: (Map<String, dynamic> response) {
    print('AI response: ${response['message']}');
  },
  onError: (String error) {
    print('Error: $error');
  },
  onAvatarLoaded: () {
    print('Avatar model loaded successfully');
  },
)
```

## Backend Requirements

The widget requires a compatible backend API with the following endpoints:

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/external/chat/` | Send chat message |
| `GET` | `/api/v1/external/avatar/speech/` | Get TTS audio |
| `POST` | `/api/v1/external/chat/upload/` | Upload file attachment |
| `GET` | `/api/v1/external/sessions/` | Get chat sessions |

### Authentication

All requests require the `X-API-Key` header:

```
X-API-Key: your_api_key
```

### Chat Request Example

```json
POST /api/v1/external/chat/
{
  "assistant_id": "uuid",
  "message": "Hello!",
  "session_id": "optional-session-uuid"
}
```

### Chat Response Example

```json
{
  "status": "success",
  "data": {
    "message": "Hello! How can I help you?",
    "session_id": "uuid",
    "visemes": [...],
    "audio_url": "https://..."
  }
}
```

## Avatar Model Requirements

Custom avatar models must be in GLB format with the following blend shapes for lip-sync:

- `viseme_sil` — Silence
- `viseme_PP` — P, B, M
- `viseme_FF` — F, V
- `viseme_TH` — Th
- `viseme_DD` — D, T, N
- `viseme_kk` — K, G
- `viseme_CH` — Ch, J, Sh
- `viseme_SS` — S, Z
- `viseme_nn` — N, L
- `viseme_RR` — R
- `viseme_aa` — A
- `viseme_E` — E
- `viseme_I` — I
- `viseme_O` — O
- `viseme_U` — U

Ready Player Me avatars are fully supported.

## Troubleshooting

### WebView not loading on Android

Ensure `android:usesCleartextTraffic="true"` is set in AndroidManifest.xml if using HTTP URLs.

### Microphone permission denied

Make sure to request microphone permission before using voice input:

```dart
import 'package:permission_handler/permission_handler.dart';

await Permission.microphone.request();
```

### Audio not playing on iOS

Add audio background mode to Info.plist if needed:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

### Model not loading

- Verify the GLB file URL is accessible
- Check CORS settings on your server
- Ensure the model has required blend shapes

## Example App

See the [example](example/) directory for a complete sample application.

## GAR (Global Application Router)

Liya AI uses a distributed backend architecture. Each user is assigned to a specific backend instance.

### Finding Your Backend URL

Your backend URL is displayed in your Liya AI dashboard under **Settings > API Configuration**:

```
https://app-{X}-ai.liyalabs.com
```

Where `{X}` is your assigned instance number (1, 2, 3, etc.).

| Instance | Backend URL |
|----------|-------------|
| 1 | `https://app-1-ai.liyalabs.com` |
| 2 | `https://app-2-ai.liyalabs.com` |
| 3 | `https://app-3-ai.liyalabs.com` |

### Dynamic Configuration

For production apps, fetch your backend URL from the mobile config endpoint:

```dart
final response = await http.get(
  Uri.parse('https://app-1-ai.liyalabs.com/api/v1/external/mobile/config/')
);
final config = jsonDecode(response.body)['data'];
// config['base_url'] contains your dynamic backend URL
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- 📧 Email: support@liyalabs.com
- 🌐 Website: https://liyalabs.com
- 📖 Docs: https://docs.liyalabs.com
