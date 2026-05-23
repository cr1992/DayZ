import { Editor } from '@tiptap/core';
import StarterKit from '@tiptap/starter-kit';
import Image from '@tiptap/extension-image';

const editor = new Editor({
  element: document.querySelector('#editor'),
  extensions: [
    StarterKit,
    Image,
  ],
  content: '<h2>Hello TipTap!</h2><p>这是一个离线的 WebView+TipTap 编辑器 Demo。</p>',
  onUpdate({ editor }) {
    const json = editor.getJSON();
    if (window.FlutterBridge) {
      window.FlutterBridge.postMessage(JSON.stringify(json));
    }
  },
});

// 全局暴露给 Flutter 调用的 JS 接口
window.insertImage = (base64) => {
  editor.chain().focus().setImage({ src: base64 }).run();
};
