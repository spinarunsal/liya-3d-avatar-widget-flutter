/**
 * Liya 3D Avatar Widget Bridge
 * JavaScript ↔ Flutter communication layer
 */

// Flutter callback interface
window.Liya3dFlutter = {
  onWebViewReady: function() {},  
  
  onAvatarLoaded: function() {
    try { window.flutter_inappwebview.callHandler('onAvatarLoaded'); } catch (e) {}
  },
  
  onAvatarError: function(error) {
    try { window.flutter_inappwebview.callHandler('onAvatarError', error); } catch (e) {}
  },
  
  onSpeakingStarted: function() {
    try { window.flutter_inappwebview.callHandler('onSpeakingStarted'); } catch (e) {}
  },
  
  onSpeakingEnded: function() {
    try { window.flutter_inappwebview.callHandler('onSpeakingEnded'); } catch (e) {}
  }
};
