import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_tokens.dart';

/// True-3D notebook preview: Google `<model-viewer>` in a WebView rendering
/// the bundled notebook.glb. The user orbits it 360° by dragging; Dart drives
/// the look through JS on stable material names baked into the model:
///   CoverBaseMat — cover colour · CoverArtMat — the user's composited design
///   SpiralMat — spiral binding shown/hidden by alpha.
class Notebook3DView extends StatefulWidget {
  final Color coverColor;
  final bool showSpiral;

  /// Composited cover design (PNG bytes); null clears the art layer.
  final Uint8List? coverArtPng;

  const Notebook3DView({
    super.key,
    required this.coverColor,
    required this.showSpiral,
    this.coverArtPng,
  });

  @override
  State<Notebook3DView> createState() => Notebook3DViewState();
}

class Notebook3DViewState extends State<Notebook3DView> {
  late final WebViewController _controller;
  bool _pageReady = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel('NotebookReady', onMessageReceived: (_) {
        _pageReady = true;
        _pushAll();
      });
    _loadPage();
  }

  Future<void> _loadPage() async {
    final glb = await rootBundle.load('assets/models/notebook.glb');
    final glbUri =
        'data:model/gltf-binary;base64,${base64Encode(glb.buffer.asUint8List())}';
    await _controller.loadHtmlString(_html(glbUri));
  }

  @override
  void didUpdateWidget(Notebook3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_pageReady) return;
    if (oldWidget.coverColor != widget.coverColor) _pushCoverColor();
    if (oldWidget.showSpiral != widget.showSpiral) _pushSpiral();
    if (!identical(oldWidget.coverArtPng, widget.coverArtPng)) _pushArt();
  }

  void _pushAll() {
    _pushCoverColor();
    _pushSpiral();
    _pushArt();
  }

  void _pushCoverColor() {
    final c = widget.coverColor;
    _controller.runJavaScript(
        'setCoverColor(${c.r}, ${c.g}, ${c.b});');
  }

  void _pushSpiral() {
    _controller.runJavaScript('setSpiralVisible(${widget.showSpiral});');
  }

  void _pushArt() {
    final png = widget.coverArtPng;
    if (png == null) {
      _controller.runJavaScript('clearCoverArt();');
    } else {
      final uri = 'data:image/png;base64,${base64Encode(png)}';
      _controller.runJavaScript("setCoverArt('$uri');");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppTokens.brLg,
      child: WebViewWidget(controller: _controller),
    );
  }

  String _html(String glbUri) => '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.5.0/model-viewer.min.js"></script>
<style>
  html, body { margin: 0; height: 100%; background: transparent; overflow: hidden; }
  model-viewer { width: 100%; height: 100%; --poster-color: transparent; }
</style>
</head>
<body>
<model-viewer id="nb" src="$glbUri" camera-controls auto-rotate auto-rotate-delay="1500"
  rotation-per-second="18deg" camera-orbit="30deg 75deg 0.42m" min-camera-orbit="auto auto 0.25m"
  max-camera-orbit="auto auto 0.8m" interaction-prompt="none" exposure="1.1"
  shadow-intensity="0.6" shadow-softness="0.9" touch-action="none"></model-viewer>
<script>
  const mv = document.getElementById('nb');
  let pendingArt = null;

  function mat(name) {
    return mv.model ? mv.model.materials.find(m => m.name === name) : null;
  }
  window.setCoverColor = (r, g, b) => {
    const m = mat('CoverBaseMat');
    if (m) m.pbrMetallicRoughness.setBaseColorFactor([r, g, b, 1]);
  };
  window.setSpiralVisible = (visible) => {
    const m = mat('SpiralMat');
    if (m) {
      const f = m.pbrMetallicRoughness.baseColorFactor;
      m.pbrMetallicRoughness.setBaseColorFactor([f[0], f[1], f[2], visible ? 1 : 0]);
    }
  };
  window.setCoverArt = async (uri) => {
    const m = mat('CoverArtMat');
    if (!m) { pendingArt = uri; return; }
    const tex = await mv.createTexture(uri);
    m.pbrMetallicRoughness.baseColorTexture.setTexture(tex);
    m.pbrMetallicRoughness.setBaseColorFactor([1, 1, 1, 1]);
  };
  window.clearCoverArt = () => {
    const m = mat('CoverArtMat');
    if (m) m.pbrMetallicRoughness.setBaseColorFactor([1, 1, 1, 0]);
  };
  mv.addEventListener('load', () => {
    if (pendingArt) { const u = pendingArt; pendingArt = null; window.setCoverArt(u); }
    NotebookReady.postMessage('ready');
  });
</script>
</body>
</html>
''';
}
