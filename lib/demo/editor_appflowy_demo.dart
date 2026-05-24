import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class EditorAppflowyDemo extends StatefulWidget {
  const EditorAppflowyDemo({super.key});

  @override
  State<EditorAppflowyDemo> createState() => _EditorAppflowyDemoState();
}

class _EditorAppflowyDemoState extends State<EditorAppflowyDemo> {
  late EditorState editorState;
  String? tempImagePath;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    editorState = EditorState.blank();
    _prepareDemoImage();
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
        tempImagePath = file.path;
        isReady = true;
      });
      debugPrint("Demo image copied to: ${file.path}");
    } catch (e) {
      debugPrint("Failed to copy demo image: $e");
    }
  }

  void _insertImage() {
    if (tempImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('图片未准备就绪')),
      );
      return;
    }

    final selection = editorState.selection;
    final transaction = editorState.transaction;
    
    // 创建图片节点
    final Node imageNode = Node(
      type: 'image',
      attributes: {
        'url': tempImagePath,
      },
    );

    if (selection != null) {
      // 插入到当前选中位置
      transaction.insertNode(selection.start.path, imageNode);
      // 将光标移到图片下方的段落（原段落被挤到了下一个位置）
      transaction.afterSelection = Selection.collapsed(
        Position(path: selection.start.path.next, offset: 0),
      );
    } else {
      // 插入到文档最开始
      transaction.insertNode([0], imageNode);
    }
    
    editorState.apply(transaction);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AppFlowy Editor Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: isReady ? _insertImage : null,
            tooltip: '插入本地图片',
          ),
        ],
      ),
      body: MobileToolbarV2(
        toolbarHeight: 48.0,
        toolbarItems: [
          textDecorationMobileToolbarItemV2,
          blocksMobileToolbarItem,
          linkMobileToolbarItem,
          dividerMobileToolbarItem,
        ],
        editorState: editorState,
        child: AppFlowyEditor(
          editorState: editorState,
          editorStyle: const EditorStyle.mobile(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          ),
        ),
      ),
    );
  }
}
