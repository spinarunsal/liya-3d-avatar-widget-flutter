import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../controllers/liya3d_avatar_controller.dart';

/// WebView wrapper for Three.js avatar scene
class Liya3dAvatarWebView extends StatefulWidget {
  /// Avatar controller for JS bridge communication
  final Liya3dAvatarController controller;

  /// Background color (transparent by default)
  final Color? backgroundColor;

  /// Whether to show loading indicator
  final bool showLoading;

  const Liya3dAvatarWebView({
    super.key,
    required this.controller,
    this.backgroundColor,
    this.showLoading = true,
  });

  @override
  State<Liya3dAvatarWebView> createState() => _Liya3dAvatarWebViewState();
}

class _Liya3dAvatarWebViewState extends State<Liya3dAvatarWebView> with SingleTickerProviderStateMixin {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _minLoadingTimeElapsed = false;
  bool _avatarReady = false;
  String? _error;
  
  late AnimationController _particleAnimController;
  
  @override
  void initState() {
    super.initState();
    _particleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    // Minimum loading time of 3 seconds for user to appreciate the animation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _minLoadingTimeElapsed = true;
          if (_avatarReady) {
            _isLoading = false;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Hide WebView during loading - show only after particle animation completes
        AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: _isLoading ? 0.0 : 1.0,
          child: InAppWebView(
          initialData: InAppWebViewInitialData(
            data: _getHtmlContent(),
            mimeType: 'text/html',
            encoding: 'utf-8',
          ),
          initialSettings: InAppWebViewSettings(
            transparentBackground: true,
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            useHybridComposition: true,
            useShouldOverrideUrlLoading: false,
            cacheEnabled: true,
            clearCache: false,
            supportZoom: false,
            disableHorizontalScroll: true,
            disableVerticalScroll: true,
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
            widget.controller.setWebViewController(controller);

            // Register JavaScript handlers
            controller.addJavaScriptHandler(
              handlerName: 'onAvatarLoaded',
              callback: (args) {
                widget.controller.onAvatarLoaded();
                if (mounted) {
                  setState(() {
                    _avatarReady = true;
                    _error = null;
                    // Only hide loading if minimum time has elapsed
                    if (_minLoadingTimeElapsed) {
                      _isLoading = false;
                    }
                  });
                }
              },
            );

            controller.addJavaScriptHandler(
              handlerName: 'onAvatarError',
              callback: (args) {
                final error = args.isNotEmpty ? args[0].toString() : 'Unknown error';
                widget.controller.onAvatarError(error);
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _error = error;
                  });
                }
              },
            );

            controller.addJavaScriptHandler(
              handlerName: 'onSpeakingStarted',
              callback: (args) {
                // Handled by controller
              },
            );

            controller.addJavaScriptHandler(
              handlerName: 'onSpeakingEnded',
              callback: (args) {
                // Handled by controller
              },
            );
          },
          onLoadStop: (controller, url) async {
            await widget.controller.onWebViewReady();
          },
          onConsoleMessage: (controller, consoleMessage) {},
        ),
        ),
        // Loading indicator - Animated Particle human silhouette
        if (widget.showLoading && _isLoading)
          AnimatedBuilder(
            animation: _particleAnimController,
            builder: (context, child) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated particle human silhouette
                    SizedBox(
                      width: 220,
                      height: 320,
                      child: CustomPaint(
                        painter: _ParticleHumanPainter(
                          animationValue: _particleAnimController.value,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Loading text with fade effect
                    Text(
                      'Generating...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6 + _particleAnimController.value * 0.2),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Progress bar
                    SizedBox(
                      width: 180,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                          minHeight: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        // Error display
        if (_error != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  String _getHtmlContent() {
    // Inline HTML with embedded JS files
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Liya 3D Avatar</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; overflow: hidden; background: transparent; }
    #avatar-container { width: 100%; height: 100%; position: relative; }
    canvas { display: block; width: 100% !important; height: 100% !important; }
  </style>
</head>
<body>
  <div id="avatar-container"></div>
  
  <script>
    ${_getThreeJsScript()}
  </script>
  <script>
    ${_getGLTFLoaderScript()}
  </script>
  <script>
    ${_getAvatarSceneScript()}
  </script>
  <script>
    ${_getWidgetBridgeScript()}
  </script>
  
  <script>
    // Pending model URL to load after scene is ready
    window.pendingModelUrl = null;
    
    document.addEventListener('DOMContentLoaded', function() {
      const container = document.getElementById('avatar-container');
      window.liya3dAvatar = new Liya3dAvatarScene(container);
      
      // Set callback for when scene is ready
      window.liya3dAvatar.onSceneReady = function() {
        if (window.pendingModelUrl) {
          window.liya3dAvatar.loadModel(window.pendingModelUrl);
          window.pendingModelUrl = null;
        }
      };
    });
    
    // Global function to load model (called from Flutter)
    window.loadAvatarModel = function(url) {
      if (window.liya3dAvatar && window.liya3dAvatar.isSceneReady) {
        window.liya3dAvatar.loadModel(url);
      } else {
        window.pendingModelUrl = url;
      }
    };
  </script>
</body>
</html>
''';
  }

  String _getThreeJsScript() {
    // Three.js will be loaded from assets
    // For now, return a CDN fallback
    return '''
// Three.js r128 will be loaded from CDN as fallback
if (typeof THREE === 'undefined') {
  var script = document.createElement('script');
  script.src = 'https://unpkg.com/three@0.128.0/build/three.min.js';
  script.onload = function() {
    loadGLTFLoader();
  };
  document.head.appendChild(script);
}

function loadGLTFLoader() {
  if (typeof THREE.GLTFLoader === 'undefined') {
    var script = document.createElement('script');
    script.src = 'https://cdn.jsdelivr.net/gh/mrdoob/three.js@r128/examples/js/loaders/GLTFLoader.js';
    script.onload = function() {};
    document.head.appendChild(script);
  }
}
''';
  }

  String _getGLTFLoaderScript() {
    // GLTFLoader placeholder - loaded via CDN
    return '// GLTFLoader loaded via CDN';
  }

  String _getAvatarSceneScript() {
    return r'''
class Liya3dAvatarScene {
  constructor(container) {
    this.container = container;
    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.avatar = null;
    this.mixer = null;
    this.clock = null;
    this.isSceneReady = false;
    this.onSceneReady = null;
    
    this.isSpeaking = false;
    this.isModelLoaded = false;
    this.currentVisemes = [];
    this.currentAudioTime = 0;
    
    // Animation parameters - tuned for natural movement (from Vue.js widget)
    this.animationParams = {
      lipSyncSpeed: 0.02,  // Much slower, natural lip movement (was 12)
      lipSyncSmoothing: 0.15,  // Smoother transitions (was 0.3)
      lipSyncIntensity: 0.5,  // Moderate mouth movement intensity
      blinkSpeed: 0.25,  // Faster blink animation
      blinkInterval: 2500,  // More frequent blinking
      eyeMoveSpeed: 0.12,  // Faster eye movement
      eyeMoveInterval: 1000,  // More frequent eye movement
      breathSpeed: 0.4,  // Slightly faster breathing
      breathIntensity: 0.015,  // More visible breathing
      microExpressionSpeed: 0.4  // More frequent micro expressions
    };
    
    this.currentMorphValues = {};
    this.targetMorphValues = {};
    
    this.idleState = {
      blinkProgress: 0,
      isBlinking: false,
      lastBlinkTime: 0,
      eyeTargetX: 0,
      eyeTargetY: 0,
      currentEyeX: 0,
      currentEyeY: 0,
      lastEyeMoveTime: 0,
      breathPhase: 0,
      microExpressionPhase: 0
    };
    
    // Viseme to morph target mapping (Ready Player Me / ARKit compatible)
    // Maps to ARKit blendshapes available in the avatar - from Vue.js widget
    this.VISEME_MORPH_MAP = {
      0: {}, // Silence - neutral (all closed)
      1: { mouthClose: 0.8, mouthPressLeft: 0.5, mouthPressRight: 0.5 }, // p, b, m - lips together
      2: { mouthFunnel: 0.6, mouthLowerDownLeft: 0.4, mouthLowerDownRight: 0.4 }, // f, v
      3: { mouthLowerDownLeft: 0.5, mouthLowerDownRight: 0.5, tongueOut: 0.3 }, // th
      4: { mouthLowerDownLeft: 0.5, mouthLowerDownRight: 0.5 }, // t, d
      5: { mouthLowerDownLeft: 0.5, mouthLowerDownRight: 0.5 }, // k, g
      6: { mouthFunnel: 0.6, mouthShrugUpper: 0.4 }, // ch, j, sh
      7: { mouthSmileLeft: 0.4, mouthSmileRight: 0.4, mouthLowerDownLeft: 0.3, mouthLowerDownRight: 0.3 }, // s, z
      8: { mouthLowerDownLeft: 0.5, mouthLowerDownRight: 0.5 }, // n
      9: { mouthLowerDownLeft: 0.5, mouthLowerDownRight: 0.5, mouthRollLower: 0.3 }, // r
      10: { mouthLowerDownLeft: 0.7, mouthLowerDownRight: 0.7, mouthUpperUpLeft: 0.4, mouthUpperUpRight: 0.4, jawOpen: 0.5 }, // a - wide open
      11: { mouthSmileLeft: 0.5, mouthSmileRight: 0.5, mouthLowerDownLeft: 0.4, mouthLowerDownRight: 0.4 }, // e
      12: { mouthSmileLeft: 0.6, mouthSmileRight: 0.6, mouthStretchLeft: 0.4, mouthStretchRight: 0.4 }, // i
      13: { mouthFunnel: 0.7, mouthLowerDownLeft: 0.5, mouthLowerDownRight: 0.5, jawOpen: 0.4 }, // o - rounded
      14: { mouthPucker: 0.7, mouthFunnel: 0.5 }, // u - pursed
    };
    
    // ARKit blendshape names used by Ready Player Me avatars
    this.ALL_MORPH_TARGETS = [
      // Mouth shapes for lip-sync
      'mouthClose', 'mouthFunnel', 'mouthPucker', 'mouthLeft', 'mouthRight',
      'mouthSmileLeft', 'mouthSmileRight', 'mouthFrownLeft', 'mouthFrownRight',
      'mouthDimpleLeft', 'mouthDimpleRight', 'mouthStretchLeft', 'mouthStretchRight',
      'mouthRollLower', 'mouthRollUpper', 'mouthShrugLower', 'mouthShrugUpper',
      'mouthPressLeft', 'mouthPressRight', 'mouthLowerDownLeft', 'mouthLowerDownRight',
      'mouthUpperUpLeft', 'mouthUpperUpRight', 'jawOpen', 'jawForward', 'jawLeft', 'jawRight',
      'tongueOut',
      // Eye shapes
      'eyeBlinkLeft', 'eyeBlinkRight', 'eyeLookUpLeft', 'eyeLookUpRight',
      'eyeLookDownLeft', 'eyeLookDownRight', 'eyeLookInLeft', 'eyeLookInRight',
      'eyeLookOutLeft', 'eyeLookOutRight', 'eyeSquintLeft', 'eyeSquintRight',
      'eyeWideLeft', 'eyeWideRight',
      // Brow shapes
      'browInnerUp', 'browDownLeft', 'browDownRight', 'browOuterUpLeft', 'browOuterUpRight',
      // Cheek/Nose
      'cheekPuff', 'cheekSquintLeft', 'cheekSquintRight', 'noseSneerLeft', 'noseSneerRight'
    ];
    
    this.morphMeshes = [];
    
    // Wait for Three.js to load
    this.waitForThreeJs();
  }
  
  waitForThreeJs() {
    if (typeof THREE !== 'undefined' && typeof THREE.GLTFLoader !== 'undefined') {
      this.clock = new THREE.Clock();
      this.initScene();
      this.animate();
      
      // Mark scene as ready and call callback
      this.isSceneReady = true;
      if (this.onSceneReady) {
        this.onSceneReady();
      }
    } else {
      setTimeout(() => this.waitForThreeJs(), 100);
    }
  }
  
  initScene() {
    const width = this.container.clientWidth || window.innerWidth;
    const height = this.container.clientHeight || window.innerHeight;
    
    this.scene = new THREE.Scene();
    
    // Camera - focused on chest/upper torso (matching Vue.js widget)
    // Lower Y position to show more of the body, not just face
    this.camera = new THREE.PerspectiveCamera(30, width / height, 0.1, 1000);
    this.camera.position.set(0, 1.35, 2.0);
    this.camera.lookAt(0, 1.2, 0);
    
    const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    
    this.renderer = new THREE.WebGLRenderer({
      antialias: !isSafari && !isIOS,
      alpha: true,
      powerPreference: isIOS ? 'low-power' : 'high-performance',
      preserveDrawingBuffer: false
    });
    
    const pixelRatio = isIOS ? Math.min(window.devicePixelRatio, 2) : window.devicePixelRatio;
    this.renderer.setPixelRatio(pixelRatio);
    this.renderer.setSize(width, height);
    this.renderer.setClearColor(0x000000, 0);
    this.renderer.outputEncoding = THREE.sRGBEncoding;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.0;
    
    this.container.appendChild(this.renderer.domElement);
    this.setupLighting();
    
    window.addEventListener('resize', () => this.onResize());
  }
  
  setupLighting() {
    const ambient = new THREE.AmbientLight(0xffffff, 0.6);
    this.scene.add(ambient);
    
    const keyLight = new THREE.DirectionalLight(0xffffff, 1.0);
    keyLight.position.set(2, 3, 2);
    this.scene.add(keyLight);
    
    const fillLight = new THREE.DirectionalLight(0xffffff, 0.4);
    fillLight.position.set(-2, 2, 2);
    this.scene.add(fillLight);
    
    const rimLight = new THREE.DirectionalLight(0xffffff, 0.3);
    rimLight.position.set(0, 2, -2);
    this.scene.add(rimLight);
  }
  
  loadModel(url) {
    if (!url) {
      console.error('[Liya3dAvatar] No model URL provided');
      this.createDefaultAvatar();
      return;
    }
    
    const loader = new THREE.GLTFLoader();
    
    loader.load(
      url,
      (gltf) => {
        if (this.avatar) {
          this.scene.remove(this.avatar);
          this.avatar = null;
        }
        
        this.avatar = gltf.scene;
        
        // Calculate bounding box to properly scale and position model
        const box = new THREE.Box3().setFromObject(this.avatar);
        const size = box.getSize(new THREE.Vector3());
        
        // Scale to fit nicely (matching Vue.js widget)
        const scale = 1.8 / size.y;
        this.avatar.scale.setScalar(scale);
        
        // Position so chest/upper torso is centered in view
        // Lower Y value to show more of the body (chest area)
        this.avatar.position.set(0, -0.5, 0);
        
        this.setupMorphTargets();
        
        if (gltf.animations && gltf.animations.length > 0) {
          this.mixer = new THREE.AnimationMixer(this.avatar);
        }
        
        this.scene.add(this.avatar);
        this.isModelLoaded = true;
        
        if (window.Liya3dFlutter && window.Liya3dFlutter.onAvatarLoaded) {
          window.Liya3dFlutter.onAvatarLoaded();
        }
      },
      (progress) => {
        // Progress tracking available if needed
      },
      (error) => {
        console.error('[Liya3dAvatar] Model loading error:', error);
        this.createDefaultAvatar();
        
        if (window.Liya3dFlutter && window.Liya3dFlutter.onAvatarError) {
          window.Liya3dFlutter.onAvatarError(error.message || 'Failed to load model');
        }
      }
    );
  }
  
  setupMorphTargets() {
    if (!this.avatar) return;
    
    this.morphMeshes = [];
    
    this.avatar.traverse((child) => {
      if (child.isMesh && child.morphTargetInfluences && child.morphTargetDictionary) {
        this.morphMeshes.push(child);
        
        for (const name of this.ALL_MORPH_TARGETS) {
          if (child.morphTargetDictionary[name] !== undefined) {
            this.currentMorphValues[name] = 0;
            this.targetMorphValues[name] = 0;
          }
        }
      }
    });
    
    }
  
  createDefaultAvatar() {
    
    if (this.avatar) {
      this.scene.remove(this.avatar);
    }
    
    this.avatar = new THREE.Group();
    
    const headGeometry = new THREE.SphereGeometry(0.15, 32, 32);
    const headMaterial = new THREE.MeshStandardMaterial({ 
      color: 0x6366F1,
      metalness: 0.1,
      roughness: 0.8
    });
    const head = new THREE.Mesh(headGeometry, headMaterial);
    head.position.y = 1.6;
    this.avatar.add(head);
    
    const bodyGeometry = new THREE.CylinderGeometry(0.12, 0.15, 0.4, 32);
    const bodyMaterial = new THREE.MeshStandardMaterial({ 
      color: 0x8B5CF6,
      metalness: 0.1,
      roughness: 0.8
    });
    const body = new THREE.Mesh(bodyGeometry, bodyMaterial);
    body.position.y = 1.25;
    this.avatar.add(body);
    
    const eyeGeometry = new THREE.SphereGeometry(0.02, 16, 16);
    const eyeMaterial = new THREE.MeshStandardMaterial({ color: 0xffffff });
    
    const leftEye = new THREE.Mesh(eyeGeometry, eyeMaterial);
    leftEye.position.set(-0.05, 1.62, 0.12);
    this.avatar.add(leftEye);
    
    const rightEye = new THREE.Mesh(eyeGeometry, eyeMaterial);
    rightEye.position.set(0.05, 1.62, 0.12);
    this.avatar.add(rightEye);
    
    this.scene.add(this.avatar);
    this.isModelLoaded = true;
    this.morphMeshes = [];
    
    if (window.Liya3dFlutter && window.Liya3dFlutter.onAvatarLoaded) {
      window.Liya3dFlutter.onAvatarLoaded();
    }
  }
  
  setSpeaking(isSpeaking) {
    this.isSpeaking = isSpeaking;
    if (!isSpeaking) {
      this.resetLipSyncMorphTargets();
    }
  }
  
  updateVisemes(visemesJson) {
    try {
      if (typeof visemesJson === 'string') {
        this.currentVisemes = JSON.parse(visemesJson);
      } else {
        this.currentVisemes = visemesJson;
      }
    } catch (e) {
      console.error('[Liya3dAvatar] Failed to parse visemes:', e);
      this.currentVisemes = [];
    }
  }
  
  updateCurrentTime(time) {
    this.currentAudioTime = time;
  }
  
  setSize(width, height) {
    if (this.camera && this.renderer) {
      this.camera.aspect = width / height;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(width, height);
    }
  }
  
  onResize() {
    const width = this.container.clientWidth || window.innerWidth;
    const height = this.container.clientHeight || window.innerHeight;
    this.setSize(width, height);
  }
  
  animate() {
    requestAnimationFrame(() => this.animate());
    
    if (!this.renderer || !this.scene || !this.camera) return;
    
    const delta = this.clock.getDelta();
    const time = this.clock.getElapsedTime();
    
    if (this.mixer) {
      this.mixer.update(delta);
    }
    
    if (this.isModelLoaded) {
      if (this.isSpeaking) {
        this.updateLipSync();
        this.updateSpeakingAnimations(time);
      } else {
        this.updateIdleAnimations(time, delta);
      }
      
      this.smoothMorphTargets(delta);
    }
    
    this.renderer.render(this.scene, this.camera);
  }
  
  updateLipSync() {
    if (!this.currentVisemes || this.currentVisemes.length === 0) {
      return;
    }
    
    let currentViseme = null;
    for (let i = this.currentVisemes.length - 1; i >= 0; i--) {
      if (this.currentVisemes[i].time <= this.currentAudioTime) {
        currentViseme = this.currentVisemes[i];
        break;
      }
    }
    
    if (!currentViseme) {
      currentViseme = this.currentVisemes[0];
    }
    
    this.applyViseme(currentViseme.viseme);
  }
  
  applyViseme(visemeId) {
    // Reset all mouth-related morph targets first
    const mouthTargets = [
      'mouthClose', 'mouthFunnel', 'mouthPucker', 'mouthLeft', 'mouthRight',
      'mouthSmileLeft', 'mouthSmileRight', 'mouthStretchLeft', 'mouthStretchRight',
      'mouthRollLower', 'mouthRollUpper', 'mouthShrugLower', 'mouthShrugUpper',
      'mouthPressLeft', 'mouthPressRight', 'mouthLowerDownLeft', 'mouthLowerDownRight',
      'mouthUpperUpLeft', 'mouthUpperUpRight', 'jawOpen', 'tongueOut'
    ];
    for (const name of mouthTargets) {
      this.targetMorphValues[name] = 0;
    }
    
    const morphTargets = this.VISEME_MORPH_MAP[visemeId] || this.VISEME_MORPH_MAP[0];
    for (const [name, value] of Object.entries(morphTargets)) {
      this.targetMorphValues[name] = value;
    }
    
    }
  
  resetLipSyncMorphTargets() {
    // Reset all mouth-related morph targets
    const mouthTargets = [
      'mouthClose', 'mouthFunnel', 'mouthPucker', 'mouthLeft', 'mouthRight',
      'mouthSmileLeft', 'mouthSmileRight', 'mouthStretchLeft', 'mouthStretchRight',
      'mouthRollLower', 'mouthRollUpper', 'mouthShrugLower', 'mouthShrugUpper',
      'mouthPressLeft', 'mouthPressRight', 'mouthLowerDownLeft', 'mouthLowerDownRight',
      'mouthUpperUpLeft', 'mouthUpperUpRight', 'jawOpen', 'tongueOut'
    ];
    for (const name of mouthTargets) {
      this.targetMorphValues[name] = 0;
    }
  }
  
  updateIdleAnimations(time, delta) {
    const now = Date.now();
    
    // Blinking
    if (!this.idleState.isBlinking && now - this.idleState.lastBlinkTime > this.animationParams.blinkInterval) {
      this.idleState.isBlinking = true;
      this.idleState.blinkProgress = 0;
      this.idleState.lastBlinkTime = now;
    }
    
    if (this.idleState.isBlinking) {
      this.idleState.blinkProgress += this.animationParams.blinkSpeed;
      
      let blinkValue = Math.sin(this.idleState.blinkProgress * Math.PI);
      
      this.targetMorphValues['eyeBlinkLeft'] = blinkValue;
      this.targetMorphValues['eyeBlinkRight'] = blinkValue;
      
      if (this.idleState.blinkProgress >= 1) {
        this.idleState.isBlinking = false;
        this.targetMorphValues['eyeBlinkLeft'] = 0;
        this.targetMorphValues['eyeBlinkRight'] = 0;
      }
    }
    
    // Eye movement
    if (now - this.idleState.lastEyeMoveTime > this.animationParams.eyeMoveInterval) {
      this.idleState.eyeTargetX = (Math.random() - 0.5) * 0.3;
      this.idleState.eyeTargetY = (Math.random() - 0.5) * 0.2;
      this.idleState.lastEyeMoveTime = now;
    }
    
    this.idleState.currentEyeX += (this.idleState.eyeTargetX - this.idleState.currentEyeX) * this.animationParams.eyeMoveSpeed;
    this.idleState.currentEyeY += (this.idleState.eyeTargetY - this.idleState.currentEyeY) * this.animationParams.eyeMoveSpeed;
    
    if (this.idleState.currentEyeX > 0) {
      this.targetMorphValues['eyeLookOutLeft'] = this.idleState.currentEyeX;
      this.targetMorphValues['eyeLookInRight'] = this.idleState.currentEyeX;
    } else {
      this.targetMorphValues['eyeLookInLeft'] = -this.idleState.currentEyeX;
      this.targetMorphValues['eyeLookOutRight'] = -this.idleState.currentEyeX;
    }
    
    if (this.idleState.currentEyeY > 0) {
      this.targetMorphValues['eyeLookUpLeft'] = this.idleState.currentEyeY;
      this.targetMorphValues['eyeLookUpRight'] = this.idleState.currentEyeY;
    } else {
      this.targetMorphValues['eyeLookDownLeft'] = -this.idleState.currentEyeY;
      this.targetMorphValues['eyeLookDownRight'] = -this.idleState.currentEyeY;
    }
    
    // Breathing - very subtle jaw movement (like breathing)
    this.idleState.breathPhase += this.animationParams.breathSpeed * 0.02;  // Much slower
    const breathValue = Math.sin(this.idleState.breathPhase) * this.animationParams.breathIntensity * 0.5;
    this.targetMorphValues['jawOpen'] = Math.max(0, breathValue);
    
    // Micro expressions - very subtle and occasional, not constant
    this.idleState.microExpressionPhase += this.animationParams.microExpressionSpeed * 0.01;  // Much slower
    
    // Only apply micro smile occasionally (every ~5 seconds)
    const microCycle = Math.sin(this.idleState.microExpressionPhase * 0.1);
    if (microCycle > 0.7) {
      const microSmile = (microCycle - 0.7) * 0.15;  // Very subtle smile
      this.targetMorphValues['mouthSmileLeft'] = Math.max(0, microSmile);
      this.targetMorphValues['mouthSmileRight'] = Math.max(0, microSmile);
    } else {
      this.targetMorphValues['mouthSmileLeft'] = 0;
      this.targetMorphValues['mouthSmileRight'] = 0;
    }
    
    const microBrow = Math.sin(this.idleState.microExpressionPhase * 0.05) * 0.03;  // Very subtle
    this.targetMorphValues['browInnerUp'] = Math.max(0, microBrow);
  }
  
  updateSpeakingAnimations(time) {
    const now = Date.now();
    
    // Subtle smile while speaking
    const speakSmile = Math.sin(time * 2) * 0.05 + 0.1;
    this.targetMorphValues['mouthSmileLeft'] = speakSmile;
    this.targetMorphValues['mouthSmileRight'] = speakSmile;
    
    // Subtle brow movement
    const speakBrow = Math.sin(time * 1.5) * 0.05 + 0.05;
    this.targetMorphValues['browInnerUp'] = speakBrow;
    
    // Eye movement during speech - more frequent than idle
    if (now - this.idleState.lastEyeMoveTime > 800) {  // Every 0.8 seconds
      this.idleState.eyeTargetX = (Math.random() - 0.5) * 0.25;
      this.idleState.eyeTargetY = (Math.random() - 0.5) * 0.15;
      this.idleState.lastEyeMoveTime = now;
    }
    
    // Smooth eye movement
    this.idleState.currentEyeX += (this.idleState.eyeTargetX - this.idleState.currentEyeX) * 0.1;
    this.idleState.currentEyeY += (this.idleState.eyeTargetY - this.idleState.currentEyeY) * 0.1;
    
    // Apply eye movement
    if (this.idleState.currentEyeX > 0) {
      this.targetMorphValues['eyeLookOutLeft'] = this.idleState.currentEyeX;
      this.targetMorphValues['eyeLookInRight'] = this.idleState.currentEyeX;
      this.targetMorphValues['eyeLookInLeft'] = 0;
      this.targetMorphValues['eyeLookOutRight'] = 0;
    } else {
      this.targetMorphValues['eyeLookInLeft'] = -this.idleState.currentEyeX;
      this.targetMorphValues['eyeLookOutRight'] = -this.idleState.currentEyeX;
      this.targetMorphValues['eyeLookOutLeft'] = 0;
      this.targetMorphValues['eyeLookInRight'] = 0;
    }
    
    if (this.idleState.currentEyeY > 0) {
      this.targetMorphValues['eyeLookUpLeft'] = this.idleState.currentEyeY;
      this.targetMorphValues['eyeLookUpRight'] = this.idleState.currentEyeY;
      this.targetMorphValues['eyeLookDownLeft'] = 0;
      this.targetMorphValues['eyeLookDownRight'] = 0;
    } else {
      this.targetMorphValues['eyeLookDownLeft'] = -this.idleState.currentEyeY;
      this.targetMorphValues['eyeLookDownRight'] = -this.idleState.currentEyeY;
      this.targetMorphValues['eyeLookUpLeft'] = 0;
      this.targetMorphValues['eyeLookUpRight'] = 0;
    }
    
    // Blinking during speech
    if (!this.idleState.isBlinking && now - this.idleState.lastBlinkTime > 2000) {
      this.idleState.isBlinking = true;
      this.idleState.blinkProgress = 0;
      this.idleState.lastBlinkTime = now;
    }
    
    if (this.idleState.isBlinking) {
      this.idleState.blinkProgress += 0.2;
      const blinkValue = Math.sin(this.idleState.blinkProgress * Math.PI);
      this.targetMorphValues['eyeBlinkLeft'] = blinkValue;
      this.targetMorphValues['eyeBlinkRight'] = blinkValue;
      
      if (this.idleState.blinkProgress >= 1) {
        this.idleState.isBlinking = false;
        this.targetMorphValues['eyeBlinkLeft'] = 0;
        this.targetMorphValues['eyeBlinkRight'] = 0;
      }
    }
  }
  
  smoothMorphTargets(delta) {
    if (!this.morphMeshes || this.morphMeshes.length === 0) {
      return;
    }
    
    // Use slower smoothing for lip-sync (from Vue.js widget)
    // lipSyncSpeed is very small (0.02), multiply by delta for frame-rate independence
    const smoothing = this.isSpeaking 
      ? Math.min(this.animationParams.lipSyncSpeed + delta * 0.5, 0.15)  // Slow, smooth transitions
      : this.animationParams.lipSyncSmoothing;
    
    // Lip-sync intensity multiplier (from Vue.js widget)
    const lipSyncIntensity = this.animationParams.lipSyncIntensity || 0.5;
    
    // Debug: log viseme morph target values once per second during speaking
    let visemeApplied = false;
    
    for (const mesh of this.morphMeshes) {
      for (const [name, targetValue] of Object.entries(this.targetMorphValues)) {
        const index = mesh.morphTargetDictionary[name];
        if (index !== undefined) {
          // Apply intensity multiplier to mouth-related morph targets
          let adjustedTarget = targetValue;
          if (name.startsWith('mouth') || name === 'jawOpen' || name === 'tongueOut') {
            adjustedTarget = targetValue * lipSyncIntensity;
          }
          
          const currentValue = mesh.morphTargetInfluences[index] || 0;
          const newValue = currentValue + (adjustedTarget - currentValue) * smoothing;
          mesh.morphTargetInfluences[index] = Math.max(0, Math.min(1, newValue));
          this.currentMorphValues[name] = newValue;
          
          // Track if any mouth morph target was applied
          if (name.startsWith('mouth') && newValue > 0.01) {
            visemeApplied = true;
          }
        }
      }
    }
    
    }
  
  cleanup() {
    
    this.isModelLoaded = false;
    
    if (this.avatar) {
      this.avatar.traverse((child) => {
        if (child.isMesh) {
          if (child.geometry) child.geometry.dispose();
          if (child.material) {
            if (Array.isArray(child.material)) {
              child.material.forEach(m => m.dispose());
            } else {
              child.material.dispose();
            }
          }
        }
      });
      this.scene.remove(this.avatar);
      this.avatar = null;
    }
    
    if (this.renderer) {
      this.renderer.dispose();
      this.renderer.forceContextLoss();
      
      if (this.renderer.domElement && this.renderer.domElement.parentNode) {
        this.renderer.domElement.parentNode.removeChild(this.renderer.domElement);
      }
      this.renderer = null;
    }
    
    if (this.scene) {
      while (this.scene.children.length > 0) {
        this.scene.remove(this.scene.children[0]);
      }
      this.scene = null;
    }
    
    this.camera = null;
    this.mixer = null;
  }
}

window.Liya3dAvatarScene = Liya3dAvatarScene;
''';
  }

  String _getWidgetBridgeScript() {
    return r'''
window.Liya3dFlutter = {
  onWebViewReady: function() {},
  
  onAvatarLoaded: function() {
    try {
      window.flutter_inappwebview.callHandler('onAvatarLoaded');
    } catch (e) {}
  },
  
  onAvatarError: function(error) {
    try {
      window.flutter_inappwebview.callHandler('onAvatarError', error);
    } catch (e) {}
  },
  
  onSpeakingStarted: function() {
    try {
      window.flutter_inappwebview.callHandler('onSpeakingStarted');
    } catch (e) {}
  },
  
  onSpeakingEnded: function() {
    try {
      window.flutter_inappwebview.callHandler('onSpeakingEnded');
    } catch (e) {}
  }
};
''';
  }

  @override
  void dispose() {
    _particleAnimController.dispose();
    widget.controller.cleanup();
    super.dispose();
  }
}

/// Custom painter for ghost/spirit particle human silhouette loading animation
/// Male figure with arms spread, no skirt, fits in view, very slow animation
class _ParticleHumanPainter extends CustomPainter {
  final double animationValue;
  
  _ParticleHumanPainter({this.animationValue = 0.0});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    // Very slow animation - multiply by small factor
    final time = animationValue * 0.5;
    
    // Scale and center the figure to fit in view
    final scale = 0.7; // Scale down to fit
    final offsetY = 0.1; // Move down slightly
    
    _drawMaleSilhouette(canvas, size, paint, time, scale, offsetY);
  }
  
  void _drawMaleSilhouette(Canvas canvas, Size size, Paint paint, double time, double scale, double offsetY) {
    // Head - circular cluster (scaled and centered)
    for (int i = 0; i < 150; i++) {
      final angle = (i / 150) * 3.14159 * 2;
      final r = 0.07 + (i % 5) * 0.006;
      final jitter = 0.008 * _noise(i * 0.2 + time * 0.1);
      final x = 0.5 + (r * _cos(angle) + jitter) * scale;
      final y = offsetY + 0.12 + (r * 0.85 * _sin(angle)) * scale;
      _drawGhostParticle(canvas, size, paint, x, y, i, time);
    }
    
    // Neck - thin column
    for (int i = 0; i < 30; i++) {
      final x = 0.5 + (_noise(i * 0.3) - 0.5) * 0.03 * scale;
      final y = offsetY + (0.20 + (i / 30) * 0.04) * scale + 0.12;
      _drawGhostParticle(canvas, size, paint, x, y, i + 150, time);
    }
    
    // Shoulders and upper torso - wider at top
    for (int i = 0; i < 200; i++) {
      final t = i / 200;
      final yPos = 0.24 + t * 0.18;
      // Male torso - wider shoulders, narrower waist
      final shoulderWidth = 0.14;
      final waistWidth = 0.08;
      final width = shoulderWidth - (shoulderWidth - waistWidth) * t;
      final x = 0.5 + ((_noise(i * 0.2) - 0.5) * width * 2) * scale;
      final y = offsetY + yPos * scale + 0.12;
      _drawGhostParticle(canvas, size, paint, x, y, i + 200, time);
    }
    
    // Lower torso / hips - straight (no skirt)
    for (int i = 0; i < 100; i++) {
      final t = i / 100;
      final yPos = 0.42 + t * 0.08;
      final width = 0.07; // Straight hips
      final x = 0.5 + ((_noise(i * 0.25 + 100) - 0.5) * width * 2) * scale;
      final y = offsetY + yPos * scale + 0.12;
      _drawGhostParticle(canvas, size, paint, x, y, i + 400, time);
    }
    
    // Left arm - extended outward
    for (int i = 0; i < 120; i++) {
      final t = i / 120;
      final baseX = 0.36 - t * 0.22;
      final baseY = 0.26 + t * 0.10;
      final scatter = 0.015 * (1 - t * 0.3);
      final x = 0.5 + ((baseX - 0.5) + (_noise(i * 0.3) - 0.5) * scatter) * scale;
      final y = offsetY + (baseY + (_noise(i * 0.2 + 50) - 0.5) * scatter) * scale + 0.12;
      _drawGhostParticle(canvas, size, paint, x, y, i + 500, time);
    }
    
    // Right arm - extended outward
    for (int i = 0; i < 120; i++) {
      final t = i / 120;
      final baseX = 0.64 + t * 0.22;
      final baseY = 0.26 + t * 0.10;
      final scatter = 0.015 * (1 - t * 0.3);
      final x = 0.5 + ((baseX - 0.5) + (_noise(i * 0.3 + 200) - 0.5) * scatter) * scale;
      final y = offsetY + (baseY + (_noise(i * 0.2 + 150) - 0.5) * scatter) * scale + 0.12;
      _drawGhostParticle(canvas, size, paint, x, y, i + 620, time);
    }
    
    // Left leg - straight pants style
    for (int i = 0; i < 140; i++) {
      final t = i / 140;
      final baseX = 0.46 - t * 0.04;
      final baseY = 0.50 + t * 0.35;
      final scatter = 0.02;
      final x = 0.5 + ((baseX - 0.5) + (_noise(i * 0.25) - 0.5) * scatter) * scale;
      final y = offsetY + (baseY + (_noise(i * 0.15) - 0.5) * 0.01) * scale + 0.12;
      _drawGhostParticle(canvas, size, paint, x, y, i + 740, time);
    }
    
    // Right leg - straight pants style
    for (int i = 0; i < 140; i++) {
      final t = i / 140;
      final baseX = 0.54 + t * 0.04;
      final baseY = 0.50 + t * 0.35;
      final scatter = 0.02;
      final x = 0.5 + ((baseX - 0.5) + (_noise(i * 0.25 + 300) - 0.5) * scatter) * scale;
      final y = offsetY + (baseY + (_noise(i * 0.15 + 300) - 0.5) * 0.01) * scale + 0.12;
      _drawGhostParticle(canvas, size, paint, x, y, i + 880, time);
    }
    
    // Subtle floating particles around figure
    for (int i = 0; i < 60; i++) {
      final angle = (i / 60) * 3.14159 * 2 + time * 0.1;
      final radius = 0.28 + 0.08 * _noise(i * 0.15 + time * 0.05);
      final x = 0.5 + radius * _cos(angle) * scale;
      final y = offsetY + (0.45 + radius * 0.6 * _sin(angle)) * scale + 0.12;
      
      paint.color = Colors.white.withOpacity(0.06 + 0.03 * _noise(i + time * 0.1));
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        1.0,
        paint,
      );
    }
  }
  
  void _drawGhostParticle(Canvas canvas, Size size, Paint paint, double x, double y, int index, double time) {
    final px = x * size.width;
    final py = y * size.height;
    
    // Particle size - small and consistent
    final sizeNoise = _noise(index * 0.08);
    final particleSize = 1.0 + sizeNoise * 1.2;
    
    // Ghost-like white color with varying opacity
    final opacityBase = 0.35 + 0.35 * _noise(index * 0.04 + time * 0.05);
    final opacity = opacityBase.clamp(0.2, 0.65);
    
    paint.color = Colors.white.withOpacity(opacity);
    canvas.drawCircle(Offset(px, py), particleSize, paint);
  }
  
  // Simple noise function for organic randomness
  double _noise(double x) {
    final n = (x * 12.9898).remainder(1.0);
    return ((n * 43758.5453).remainder(1.0)).abs();
  }
  
  double _sin(double x) {
    x = x.remainder(6.28318);
    if (x < 0) x += 6.28318;
    if (x < 3.14159) {
      return 4 * x * (3.14159 - x) / (3.14159 * 3.14159);
    } else {
      x = x - 3.14159;
      return -4 * x * (3.14159 - x) / (3.14159 * 3.14159);
    }
  }
  
  double _cos(double x) => _sin(x + 1.5708);

  @override
  bool shouldRepaint(covariant _ParticleHumanPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
