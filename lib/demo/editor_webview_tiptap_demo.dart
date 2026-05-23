import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dayz/demo/editor_bridge.dart';

class EditorWebviewTiptapDemo extends StatefulWidget {
  const EditorWebviewTiptapDemo({super.key});

  @override
  State<EditorWebviewTiptapDemo> createState() => _EditorWebviewTiptapDemoState();
}

class _EditorWebviewTiptapDemoState extends State<EditorWebviewTiptapDemo> {
  late final WebViewController _controller;
  EditorBridge? _bridge;
  String? _tempImagePath;
  bool _isImageReady = false;
  String _latestJson = "{}";

  @override
  void initState() {
    super.initState();
    _prepareDemoImage();
    _initWebViewController();
  }

  Future<void> _prepareDemoImage() async {
    try {
      final byteData = await rootBundle.load('assets/editor/demo_image.png');
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/demo_image.png');
      await file.writeAsBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );
      setState(() {
        _tempImagePath = file.path;
        _isImageReady = true;
      });
      debugPrint("WebView Demo image cached to: ${file.path}");
    } catch (e) {
      debugPrint("WebView Demo failed to copy image: $e");
    }
  }

  void _initWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadFlutterAsset('assets/editor/editor.html');

    _bridge = EditorBridge(
      controller: _controller,
      onContentChanged: (json) {
        setState(() {
          _latestJson = json;
        });
        debugPrint("TipTap Content: $json");
      },
    );
  }

  Future<void> _insertImage() async {
    if (!_isImageReady || _tempImagePath == null || _bridge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('图片未就绪或 Bridge 未初始化')),
      );
      return;
    }

    try {
      final file = File(_tempImagePath!);
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final base64Url = 'data:image/png;base64,$base64String';

      await _bridge!.insertImage(base64Url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已向 WebView 发送插入图片指令')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('读取图片失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView+TipTap Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _isImageReady ? _insertImage : null,
            tooltip: '插入本地图片',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
          Container(
            height: 120,
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[200],
            child: SingleChildScrollView(
              child: Text(
                '最新 JSON 回显:\n$_latestJson',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
