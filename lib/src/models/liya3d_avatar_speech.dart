/// Viseme data for lip-sync animation
class Liya3dVisemeData {
  /// Time offset in seconds
  final double time;

  /// Viseme ID (0-14)
  final int viseme;

  /// Duration of this viseme in seconds
  final double duration;

  const Liya3dVisemeData({
    required this.time,
    required this.viseme,
    required this.duration,
  });

  factory Liya3dVisemeData.fromJson(Map<String, dynamic> json) {
    return Liya3dVisemeData(
      time: (json['time'] as num).toDouble(),
      viseme: json['viseme'] as int,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'viseme': viseme,
      'duration': duration,
    };
  }
}

/// Response from /api/v1/external/avatar/speech/ endpoint
class Liya3dAvatarSpeechResponse {
  /// List of viseme data for lip-sync
  final List<Liya3dVisemeData> visemes;

  /// Total audio duration in seconds
  final double duration;

  /// Original text that was spoken
  final String text;

  /// Base64 encoded audio data
  final String? audioBase64;

  /// Audio format (e.g., 'mp3', 'wav')
  final String? audioFormat;

  /// Audio MIME type
  final String? audioMime;

  const Liya3dAvatarSpeechResponse({
    required this.visemes,
    required this.duration,
    required this.text,
    this.audioBase64,
    this.audioFormat,
    this.audioMime,
  });

  factory Liya3dAvatarSpeechResponse.fromJson(Map<String, dynamic> json) {
    final visemesList = json['visemes'] as List? ?? [];
    return Liya3dAvatarSpeechResponse(
      visemes: visemesList
          .map((v) => Liya3dVisemeData.fromJson(v as Map<String, dynamic>))
          .toList(),
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      text: json['text'] as String? ?? '',
      audioBase64: json['audio_base64'] as String? ?? json['audio'] as String?,
      audioFormat: json['audio_format'] as String? ?? 'mp3',
      audioMime: json['audio_mime'] as String? ?? 'audio/mpeg',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visemes': visemes.map((v) => v.toJson()).toList(),
      'duration': duration,
      'text': text,
      if (audioBase64 != null) 'audio_base64': audioBase64,
      if (audioFormat != null) 'audio_format': audioFormat,
      if (audioMime != null) 'audio_mime': audioMime,
    };
  }

  /// Check if audio data is available
  bool get hasAudio => audioBase64 != null && audioBase64!.isNotEmpty;
}

/// Viseme to morph target mapping (ARKit blendshapes)
/// Maps OpenAI viseme IDs to Ready Player Me morph target names
class Liya3dVisemeMorphMap {
  static const Map<int, Map<String, double>> mapping = {
    0: {'viseme_sil': 1.0},                                    // silence
    1: {'viseme_PP': 0.8, 'viseme_FF': 0.2},                  // æ, ə, ʌ
    2: {'viseme_aa': 1.0},                                     // ɑ
    3: {'viseme_aa': 0.6, 'viseme_O': 0.4},                   // ɔ
    4: {'viseme_E': 0.8, 'viseme_I': 0.2},                    // ɛ, ʊ
    5: {'viseme_E': 0.5, 'viseme_RR': 0.5},                   // ɝ
    6: {'viseme_I': 0.8, 'viseme_E': 0.2},                    // j, i, ɪ
    7: {'viseme_U': 0.8, 'viseme_O': 0.2},                    // w, u
    8: {'viseme_O': 1.0},                                      // o
    9: {'viseme_aa': 0.5, 'viseme_U': 0.5},                   // aʊ
    10: {'viseme_O': 0.6, 'viseme_I': 0.4},                   // ɔɪ
    11: {'viseme_aa': 0.6, 'viseme_I': 0.4},                  // aɪ
    12: {'viseme_kk': 0.6, 'viseme_nn': 0.4},                 // h
    13: {'viseme_RR': 1.0},                                    // ɹ
    14: {'viseme_nn': 0.8, 'viseme_DD': 0.2},                 // l
    15: {'viseme_SS': 0.8, 'viseme_TH': 0.2},                 // s, z
    16: {'viseme_CH': 0.8, 'viseme_SS': 0.2},                 // ʃ, tʃ, dʒ, ʒ
    17: {'viseme_TH': 1.0},                                    // ð
    18: {'viseme_FF': 1.0},                                    // f, v
    19: {'viseme_DD': 0.8, 'viseme_nn': 0.2},                 // d, t, n, θ
    20: {'viseme_kk': 1.0},                                    // k, g, ŋ
    21: {'viseme_PP': 1.0},                                    // p, b, m
  };

  /// Get morph target weights for a viseme ID
  static Map<String, double> getMorphTargets(int visemeId) {
    return mapping[visemeId] ?? {'viseme_sil': 1.0};
  }

  /// All morph target names used in lip-sync
  static const List<String> allMorphTargets = [
    'viseme_sil',
    'viseme_PP',
    'viseme_FF',
    'viseme_TH',
    'viseme_DD',
    'viseme_kk',
    'viseme_CH',
    'viseme_SS',
    'viseme_nn',
    'viseme_RR',
    'viseme_aa',
    'viseme_E',
    'viseme_I',
    'viseme_O',
    'viseme_U',
  ];
}
