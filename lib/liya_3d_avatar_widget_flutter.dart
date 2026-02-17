/// Liya AI 3D Talking Avatar Widget for Flutter
///
/// A Flutter widget that provides an AI-powered 3D talking avatar with chat functionality.
/// Uses WebView + Three.js for avatar rendering and native Flutter for UI/Chat.
library liya_3d_avatar_widget_flutter;

// Models
export 'src/models/liya3d_config.dart';
export 'src/models/liya3d_message.dart';
export 'src/models/liya3d_enums.dart';
export 'src/models/liya3d_api_response.dart';
export 'src/models/liya3d_avatar_speech.dart';
export 'src/models/liya3d_file_attachment.dart';

// Services
export 'src/services/liya3d_api_service.dart';
export 'src/services/liya3d_avatar_service.dart';
export 'src/services/liya3d_audio_service.dart';
export 'src/services/liya3d_storage_service.dart';

// Controllers
export 'src/controllers/liya3d_chat_controller.dart';
export 'src/controllers/liya3d_avatar_controller.dart';
export 'src/controllers/liya3d_voice_controller.dart';

// Widgets
export 'src/widgets/liya3d_avatar_widget.dart';
export 'src/widgets/liya3d_kiosk_widget.dart';
export 'src/widgets/liya3d_avatar_webview.dart';
export 'src/widgets/liya3d_toggle_button.dart';
export 'src/widgets/liya3d_header.dart';
export 'src/widgets/liya3d_message_list.dart';
export 'src/widgets/liya3d_message_bubble.dart';
export 'src/widgets/liya3d_chat_input.dart';
export 'src/widgets/liya3d_premium_overlay.dart';

// i18n
export 'src/i18n/liya3d_translations.dart';

// Utils
export 'src/utils/liya3d_colors.dart';
export 'src/utils/liya3d_glass_decoration.dart';
