/**
 * Liya 3D Avatar Scene
 * Three.js avatar rendering with lip-sync support
 * Ported from Vue.js AvatarScene.vue
 */

class Liya3dAvatarScene {
  constructor(container) {
    this.container = container;
    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.avatar = null;
    this.mixer = null;
    this.clock = new THREE.Clock();
    
    // State
    this.isSpeaking = false;
    this.isModelLoaded = false;
    this.currentVisemes = [];
    this.currentAudioTime = 0;
    
    // Animation params - matched to Vue.js widget for consistency
    this.animationParams = {
      lipSyncSpeed: 0.02,         // Vue.js default - natural lip movement
      lipSyncSmoothing: 0.08,     // Vue.js smoothing factor
      lipSyncIntensity: 0.5,      // Vue.js default - moderate mouth movement
      jawOpenIntensity: 0.5,      // Moderate jaw opening
      blinkSpeed: 0.25,           // Vue.js default
      blinkIntervalMin: 1500,     // Vue.js default
      blinkIntervalMax: 3500,     // Vue.js default
      blinkInterval: 2500,        // Average for compatibility
      eyeMoveSpeed: 0.12,         // Vue.js default
      eyeMoveIntervalMin: 500,    // Vue.js default
      eyeMoveIntervalMax: 1500,   // Vue.js default
      eyeMoveInterval: 1000,      // Average for compatibility
      eyeMoveRange: 0.4,          // Vue.js default
      breathSpeed: 0.4,           // Vue.js breathingSpeed
      breathIntensity: 0.015,     // Vue.js breathingIntensity
      microExpressionSpeed: 0.4,  // Vue.js default
      microExpressionIntensity: 0.08, // Vue.js default
      speakingBrowIntensity: 0.05,    // Vue.js default
      speakingSmileIntensity: 0.2,    // Vue.js default
      handGestureSpeed: 0.5,      // Vue.js default
      handGestureIntensity: 0.2   // Vue.js default
    };
    
    // Morph target values
    this.currentMorphValues = {};
    this.targetMorphValues = {};
    
    // Idle animation state
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
      microExpressionPhase: 0,
      handGesturePhase: 0
    };
    
    // Viseme to morph target mapping (ARKit blendshapes)
    this.VISEME_MORPH_MAP = {
      0: { viseme_sil: 1.0 },                                    // silence
      1: { viseme_PP: 0.8, viseme_FF: 0.2 },                    // æ, ə, ʌ
      2: { viseme_aa: 1.0 },                                     // ɑ
      3: { viseme_aa: 0.6, viseme_O: 0.4 },                     // ɔ
      4: { viseme_E: 0.8, viseme_I: 0.2 },                      // ɛ, ʊ
      5: { viseme_E: 0.5, viseme_RR: 0.5 },                     // ɝ
      6: { viseme_I: 0.8, viseme_E: 0.2 },                      // j, i, ɪ
      7: { viseme_U: 0.8, viseme_O: 0.2 },                      // w, u
      8: { viseme_O: 1.0 },                                      // o
      9: { viseme_aa: 0.5, viseme_U: 0.5 },                     // aʊ
      10: { viseme_O: 0.6, viseme_I: 0.4 },                     // ɔɪ
      11: { viseme_aa: 0.6, viseme_I: 0.4 },                    // aɪ
      12: { viseme_kk: 0.6, viseme_nn: 0.4 },                   // h
      13: { viseme_RR: 1.0 },                                    // ɹ
      14: { viseme_nn: 0.8, viseme_DD: 0.2 },                   // l
      15: { viseme_SS: 0.8, viseme_TH: 0.2 },                   // s, z
      16: { viseme_CH: 0.8, viseme_SS: 0.2 },                   // ʃ, tʃ, dʒ, ʒ
      17: { viseme_TH: 1.0 },                                    // ð
      18: { viseme_FF: 1.0 },                                    // f, v
      19: { viseme_DD: 0.8, viseme_nn: 0.2 },                   // d, t, n, θ
      20: { viseme_kk: 1.0 },                                    // k, g, ŋ
      21: { viseme_PP: 1.0 }                                     // p, b, m
    };
    
    // All morph target names
    this.ALL_MORPH_TARGETS = [
      'viseme_sil', 'viseme_PP', 'viseme_FF', 'viseme_TH', 'viseme_DD',
      'viseme_kk', 'viseme_CH', 'viseme_SS', 'viseme_nn', 'viseme_RR',
      'viseme_aa', 'viseme_E', 'viseme_I', 'viseme_O', 'viseme_U',
      'eyeBlinkLeft', 'eyeBlinkRight', 'eyeLookUpLeft', 'eyeLookUpRight',
      'eyeLookDownLeft', 'eyeLookDownRight', 'eyeLookInLeft', 'eyeLookInRight',
      'eyeLookOutLeft', 'eyeLookOutRight', 'browInnerUp', 'browDownLeft',
      'browDownRight', 'browOuterUpLeft', 'browOuterUpRight', 'mouthSmileLeft',
      'mouthSmileRight', 'mouthFrownLeft', 'mouthFrownRight', 'jawOpen'
    ];
    
    this.initScene();
    this.animate();
  }
  
  initScene() {
    const width = this.container.clientWidth || window.innerWidth;
    const height = this.container.clientHeight || window.innerHeight;
    
    // Scene
    this.scene = new THREE.Scene();
    
    // Camera
    this.camera = new THREE.PerspectiveCamera(35, width / height, 0.1, 1000);
    this.camera.position.set(0, 1.5, 2.5);
    this.camera.lookAt(0, 1.4, 0);
    
    // Renderer
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
    
    // Lighting
    this.setupLighting();
    
    // Handle resize
    window.addEventListener('resize', () => this.onResize());
  }
  
  setupLighting() {
    // Ambient light
    const ambient = new THREE.AmbientLight(0xffffff, 0.6);
    this.scene.add(ambient);
    
    // Key light (main)
    const keyLight = new THREE.DirectionalLight(0xffffff, 1.0);
    keyLight.position.set(2, 3, 2);
    this.scene.add(keyLight);
    
    // Fill light
    const fillLight = new THREE.DirectionalLight(0xffffff, 0.4);
    fillLight.position.set(-2, 2, 2);
    this.scene.add(fillLight);
    
    // Rim light
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
        // Remove existing avatar
        if (this.avatar) {
          this.scene.remove(this.avatar);
          this.avatar = null;
        }
        
        this.avatar = gltf.scene;
        
        // Setup avatar
        this.avatar.position.set(0, 0, 0);
        this.avatar.scale.set(1, 1, 1);
        
        // Find and setup morph targets
        this.setupMorphTargets();
        
        // Setup animations if available
        if (gltf.animations && gltf.animations.length > 0) {
          this.mixer = new THREE.AnimationMixer(this.avatar);
        }
        
        this.scene.add(this.avatar);
        this.isModelLoaded = true;
        
        // Notify Flutter
        if (window.Liya3dFlutter && window.Liya3dFlutter.onAvatarLoaded) {
          window.Liya3dFlutter.onAvatarLoaded();
        }
      },
      (progress) => {},
      (error) => {
        console.error('[Liya3dAvatar] Model loading error:', error);
        this.createDefaultAvatar();
        
        // Notify Flutter
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
        
        // Initialize morph values
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
    
    // Head
    const headGeometry = new THREE.SphereGeometry(0.15, 32, 32);
    const headMaterial = new THREE.MeshStandardMaterial({ 
      color: 0x6366F1,
      metalness: 0.1,
      roughness: 0.8
    });
    const head = new THREE.Mesh(headGeometry, headMaterial);
    head.position.y = 1.6;
    this.avatar.add(head);
    
    // Body
    const bodyGeometry = new THREE.CylinderGeometry(0.12, 0.15, 0.4, 32);
    const bodyMaterial = new THREE.MeshStandardMaterial({ 
      color: 0x8B5CF6,
      metalness: 0.1,
      roughness: 0.8
    });
    const body = new THREE.Mesh(bodyGeometry, bodyMaterial);
    body.position.y = 1.25;
    this.avatar.add(body);
    
    // Eyes
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
    
    // Notify Flutter
    if (window.Liya3dFlutter && window.Liya3dFlutter.onAvatarLoaded) {
      window.Liya3dFlutter.onAvatarLoaded();
    }
  }
  
  setSpeaking(isSpeaking) {
    this.isSpeaking = isSpeaking;
    
    if (!isSpeaking) {
      // Reset lip-sync morph targets
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
    
    const delta = this.clock.getDelta();
    const time = this.clock.getElapsedTime();
    
    // Update mixer
    if (this.mixer) {
      this.mixer.update(delta);
    }
    
    // Update animations
    if (this.isModelLoaded) {
      if (this.isSpeaking) {
        this.updateLipSync();
        this.updateSpeakingAnimations(time);
      } else {
        this.updateIdleAnimations(time, delta);
      }
      
      // Smooth morph target transitions
      this.smoothMorphTargets(delta);
    }
    
    // Render
    if (this.renderer && this.scene && this.camera) {
      this.renderer.render(this.scene, this.camera);
    }
  }
  
  updateLipSync() {
    if (!this.currentVisemes || this.currentVisemes.length === 0) return;
    
    // Find current viseme based on audio time
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
    
    // Apply viseme morph targets
    this.applyViseme(currentViseme.viseme);
  }
  
  applyViseme(visemeId) {
    // Reset all lip-sync morph targets
    for (const name of this.ALL_MORPH_TARGETS) {
      if (name.startsWith('viseme_')) {
        this.targetMorphValues[name] = 0;
      }
    }
    
    // Apply new viseme with intensity (Vue.js style)
    const morphTargets = this.VISEME_MORPH_MAP[visemeId] || this.VISEME_MORPH_MAP[0];
    const intensity = this.animationParams.lipSyncIntensity || 0.5;
    
    for (const [name, value] of Object.entries(morphTargets)) {
      // Apply intensity directly like Vue.js
      this.targetMorphValues[name] = intensity;
    }
    
    // Add jaw opening based on viseme type (Vue.js style mouthOpen calculation)
    // Open vowels get more jaw opening
    let jawAmount = 0;
    if (visemeId === 0) {
      jawAmount = 0; // Silence
    } else if (visemeId >= 10 && visemeId <= 14) {
      // Wide open vowels
      jawAmount = 0.6 + (visemeId - 10) * 0.08;
    } else if (visemeId >= 1 && visemeId <= 2) {
      // Closed consonants
      jawAmount = 0.1;
    } else if (visemeId === 7 || visemeId === 11 || visemeId === 12) {
      // Round vowels
      jawAmount = 0.3;
    } else {
      // Other visemes
      jawAmount = 0.25 + visemeId * 0.03;
    }
    
    this.targetMorphValues['jawOpen'] = jawAmount * intensity;
  }
  
  resetLipSyncMorphTargets() {
    for (const name of this.ALL_MORPH_TARGETS) {
      if (name.startsWith('viseme_')) {
        this.targetMorphValues[name] = 0;
      }
    }
    // Also reset jaw
    this.targetMorphValues['jawOpen'] = 0;
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
      
      // Blink curve: quick close, slower open
      let blinkValue;
      if (this.idleState.blinkProgress < 0.5) {
        blinkValue = Math.sin(this.idleState.blinkProgress * Math.PI);
      } else {
        blinkValue = Math.sin(this.idleState.blinkProgress * Math.PI);
      }
      
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
    
    // Apply eye look
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
    
    // Breathing (subtle jaw movement)
    this.idleState.breathPhase += this.animationParams.breathSpeed;
    const breathValue = Math.sin(this.idleState.breathPhase) * this.animationParams.breathIntensity;
    this.targetMorphValues['jawOpen'] = Math.max(0, breathValue);
    
    // Micro expressions
    this.idleState.microExpressionPhase += this.animationParams.microExpressionSpeed;
    const microSmile = Math.sin(this.idleState.microExpressionPhase * 0.7) * 0.1 + 0.05;
    this.targetMorphValues['mouthSmileLeft'] = Math.max(0, microSmile);
    this.targetMorphValues['mouthSmileRight'] = Math.max(0, microSmile);
    
    const microBrow = Math.sin(this.idleState.microExpressionPhase * 0.3) * 0.05;
    this.targetMorphValues['browInnerUp'] = Math.max(0, microBrow);
  }
  
  updateSpeakingAnimations(time) {
    // Enhanced expressions while speaking
    const speakSmile = Math.sin(time * 2) * 0.1 + 0.15;
    this.targetMorphValues['mouthSmileLeft'] = speakSmile;
    this.targetMorphValues['mouthSmileRight'] = speakSmile;
    
    const speakBrow = Math.sin(time * 1.5) * 0.1 + 0.1;
    this.targetMorphValues['browInnerUp'] = speakBrow;
  }
  
  smoothMorphTargets(delta) {
    if (!this.morphMeshes || this.morphMeshes.length === 0) return;
    
    for (const mesh of this.morphMeshes) {
      for (const [name, targetValue] of Object.entries(this.targetMorphValues)) {
        const index = mesh.morphTargetDictionary[name];
        if (index !== undefined) {
          const currentValue = mesh.morphTargetInfluences[index] || 0;
          const diff = targetValue - currentValue;
          const absDiff = Math.abs(diff);
          
          // Vue.js style exponential smoothing
          // Smaller movements are slower, larger movements catch up faster
          const smoothFactor = Math.min(
            this.animationParams.lipSyncSpeed * (0.5 + absDiff * 0.5), 
            this.animationParams.lipSyncSmoothing
          );
          
          let newValue = currentValue + diff * smoothFactor;
          
          // Snap to zero or target if very close (avoid jitter)
          if (Math.abs(newValue) < 0.005) newValue = 0;
          if (Math.abs(newValue - targetValue) < 0.005) newValue = targetValue;
          
          mesh.morphTargetInfluences[index] = Math.max(0, Math.min(1, newValue));
          this.currentMorphValues[name] = newValue;
        }
      }
    }
  }
  
  cleanup() {
    
    // Stop animation loop
    this.isModelLoaded = false;
    
    // Dispose geometries and materials
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
    
    // Dispose renderer
    if (this.renderer) {
      this.renderer.dispose();
      this.renderer.forceContextLoss();
      
      if (this.renderer.domElement && this.renderer.domElement.parentNode) {
        this.renderer.domElement.parentNode.removeChild(this.renderer.domElement);
      }
      this.renderer = null;
    }
    
    // Clear scene
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

// Export for global access
window.Liya3dAvatarScene = Liya3dAvatarScene;
