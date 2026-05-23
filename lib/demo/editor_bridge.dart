import 'package:webview_flutter/webview_flutter.dart';

class EditorBridge {
  final WebViewController controller;
  final Function(String json) onContentChanged;

  EditorBridge({
    required this.controller,
    required this.onContentChanged,
  }) {
    // 注册 JS 回调通道
    controller.addJavaScriptChannel(
      'FlutterBridge',
      onMessageReceived: (JavaScriptMessage message) {
        onContentChanged(message.message);
      },
    );
  }

  /// 向 WebView TipTap 注入 Base64 格式的图片数据
  Future<void> insertImage(String base64Data) async {
    // 注入 Base64 URL 渲染图片
    final jsCode = "window.insertImage('$base64Data');";
    await controller.runJavaScript(jsCode);
  }
}
