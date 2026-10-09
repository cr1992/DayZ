/* DZ.picker —— 微信式全屏图片选择器。业务无关、零依赖。
   多选 + 顺序编号徽标 · 相机格 · 预览（复用 DZ.lightbox）· 原图开关 · 完成(N)。
   暖近黑底（--media-*），编号/完成钮走主题 accent。

   用法：
     DZ.picker({
       assets:['a.png','b.png',…],   // 相册缩略图
       max:9,                          // 最多选数（默认 9）
       onDone(srcs){…},                // 点「完成」回调，srcs = 选中顺序
       onCamera(){…},                  // 点相机格（缺省 toast）
       host
     });

   返回：{ close(), el }
   Flutter 对应：wechat_assets_picker（AssetPicker.pickAssets：maxAssets/预览/原图/编号全内置），
                或 photo_manager 取资源 + 自绘 GridView + PageController。 */
(function () {
  var DZ = (window.DZ = window.DZ || {});
  var EXIT = 240;
  var CAM = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 8a2 2 0 0 1 2-2h1.4l1-2h5.2l1 2H18a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z"/><circle cx="12" cy="12.6" r="3.2"/></svg>';
  var CARET = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m6 9 6 6 6-6"/></svg>';
  var CHECK = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>';
  var CROPS = ['50% 50%', '50% 22%', '32% 50%', '68% 60%', '50% 80%', '24% 34%'];

  function hostOf(opts) {
    return (opts && opts.host) || document.querySelector('.pg') || document.body;
  }

  DZ.picker = function (opts) {
    opts = opts || {};
    var assets = opts.assets || [];
    var max = opts.max || 9;
    var album = opts.album || '最近项目';
    var scope = hostOf(opts);
    if (getComputedStyle(scope).position === 'static') scope.style.position = 'relative';

    var sel = []; /* 选中的格对象，按点选顺序（按格身份去重，非 src——原型里缩略图可能复用同一张）*/

    var root = document.createElement('div');
    root.className = 'pk';
    root.setAttribute('role', 'dialog');
    root.setAttribute('aria-modal', 'true');
    root.innerHTML =
      '<div class="pk-top">' +
        '<button class="pk-cancel" type="button">取消</button>' +
        '<button class="pk-album" type="button">' + album + ' ' + CARET + '</button>' +
      '</div>' +
      '<div class="pk-grid"></div>' +
      '<div class="pk-foot">' +
        '<button class="pk-preview" type="button" disabled>预览</button>' +
        '<button class="pk-orig" type="button"><span class="box"></span>原图</button>' +
        '<button class="pk-done" type="button" disabled>完成</button>' +
      '</div>';

    var grid = root.querySelector('.pk-grid');
    var previewBtn = root.querySelector('.pk-preview');
    var origBtn = root.querySelector('.pk-orig');
    var doneBtn = root.querySelector('.pk-done');

    /* 相机格 */
    var cam = document.createElement('button');
    cam.className = 'pk-cam';
    cam.type = 'button';
    cam.innerHTML = CAM + '<span>拍照</span>';
    cam.addEventListener('click', function () {
      if (typeof opts.onCamera === 'function') opts.onCamera();
      else if (DZ.toast) DZ.toast('打开相机');
    });
    grid.appendChild(cam);

    var cells = [];
    assets.forEach(function (src, i) {
      var c = document.createElement('button');
      c.className = 'pk-cell';
      c.type = 'button';
      c.innerHTML = '<img src="' + src + '" alt=""><span class="pk-badge"></span>';
      c.querySelector('img').style.objectPosition = CROPS[i % CROPS.length];
      var cell = { src: src, el: c };
      c.addEventListener('click', function () { toggle(cell); });
      grid.appendChild(c);
      cells.push(cell);
    });

    function renumber() {
      cells.forEach(function (cell) {
        var n = sel.indexOf(cell);
        var badge = cell.el.querySelector('.pk-badge');
        if (n >= 0) { cell.el.classList.add('sel'); badge.textContent = String(n + 1); }
        else { cell.el.classList.remove('sel'); badge.textContent = ''; }
      });
      var k = sel.length;
      previewBtn.disabled = k === 0;
      doneBtn.disabled = k === 0;
      doneBtn.textContent = k ? ('完成 (' + k + ')') : '完成';
    }
    function toggle(cell) {
      var i = sel.indexOf(cell);
      if (i >= 0) sel.splice(i, 1);
      else {
        if (sel.length >= max) { if (DZ.toast) DZ.toast('最多选择 ' + max + ' 张'); return; }
        sel.push(cell);
      }
      renumber();
    }

    previewBtn.addEventListener('click', function () {
      if (sel.length && DZ.lightbox) DZ.lightbox({ images: sel.map(function (c) { return c.src; }), host: scope });
    });
    origBtn.addEventListener('click', function () {
      var on = origBtn.classList.toggle('on');
      origBtn.querySelector('.box').innerHTML = on ? CHECK : '';
    });

    var closed = false;
    function close_() {
      if (closed) return; closed = true;
      root.classList.remove('in');
      setTimeout(function () { if (root.parentNode) root.parentNode.removeChild(root); }, EXIT);
      document.removeEventListener('keydown', onKey);
    }
    function onKey(e) { if (e.key === 'Escape') close_(); }
    root.querySelector('.pk-cancel').addEventListener('click', close_);
    doneBtn.addEventListener('click', function () {
      if (!sel.length) return;
      var out = sel.map(function (c) { return c.src; });
      close_();
      if (typeof opts.onDone === 'function') opts.onDone(out);
    });
    document.addEventListener('keydown', onKey);

    scope.appendChild(root);
    void root.offsetWidth;
    root.classList.add('in');
    renumber();

    return { close: close_, el: root };
  };
})();
