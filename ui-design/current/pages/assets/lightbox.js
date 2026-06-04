/* DZ.lightbox —— 全屏大图查看器（左右滑动）。业务无关、零依赖。
   照片在暖近黑底（--media-*）上铺满呈现，横向 scroll-snap 翻页，顶部计数 + 关闭。

   用法：
     DZ.lightbox({ images:['a.png', {src:'b.png', caption:'青梅'}], index:0, host });

   自动接线（推荐）：给容器加 `data-lightbox`，容器内所有 <img> 自动成一组，
   点哪张就从哪张打开。容器或单图可带 `data-caption` 显示底部说明。
     <div class="gallery" data-lightbox> …<img>… </div>

   返回：{ close(), el }
   Flutter 对应：PhotoViewGallery.builder + PageController(initialPage:index)，
                backgroundDecoration 暖近黑，onPageChanged 更新计数；点空白/关闭键退出。 */
(function () {
  var DZ = (window.DZ = window.DZ || {});
  var EXIT = 240;
  var CLOSE = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 6l12 12M18 6 6 18"/></svg>';

  function hostOf(opts) {
    return (opts && opts.host) || document.querySelector('.pg') || document.body;
  }

  DZ.lightbox = function (opts) {
    opts = opts || {};
    var imgs = (opts.images || []).map(function (x) { return typeof x === 'string' ? { src: x } : x; });
    if (!imgs.length) return { close: function () {} };
    var start = Math.max(0, Math.min(opts.index || 0, imgs.length - 1));
    var scope = hostOf(opts);
    if (getComputedStyle(scope).position === 'static') scope.style.position = 'relative';
    var multi = imgs.length > 1;
    var hasCaption = imgs.some(function (im) { return im.caption; });

    var root = document.createElement('div');
    root.className = 'lbx';
    root.setAttribute('role', 'dialog');
    root.setAttribute('aria-modal', 'true');

    var track = document.createElement('div');
    track.className = 'lbx-track';
    imgs.forEach(function (im) {
      var s = document.createElement('div');
      s.className = 'lbx-slide';
      var img = document.createElement('img');
      img.src = im.src; img.alt = im.caption || '';
      s.appendChild(img);
      track.appendChild(s);
    });

    var top = document.createElement('div');
    top.className = 'lbx-top';
    var close = document.createElement('button');
    close.className = 'lbx-close';
    close.type = 'button';
    close.innerHTML = CLOSE;
    close.setAttribute('aria-label', '关闭');
    top.appendChild(close);
    var count = document.createElement('div');
    count.className = 'lbx-count';
    if (multi) top.appendChild(count);

    var foot = hasCaption ? document.createElement('div') : null;
    if (foot) foot.className = 'lbx-foot';

    root.appendChild(track);
    root.appendChild(top);
    if (foot) root.appendChild(foot);

    var cur = start;
    function setIdx(i) {
      if (multi) count.textContent = (i + 1) + ' / ' + imgs.length;
      if (foot) foot.textContent = (imgs[i] && imgs[i].caption) || '';
    }
    setIdx(cur);

    var closed = false;
    function close_() {
      if (closed) return; closed = true;
      root.classList.remove('in');
      setTimeout(function () { if (root.parentNode) root.parentNode.removeChild(root); }, EXIT);
      document.removeEventListener('keydown', onKey);
      if (typeof opts.onClose === 'function') opts.onClose();
    }
    close.addEventListener('click', close_);
    /* 点空白（非图片）即退出；点图片本身不退出，方便细看 */
    track.addEventListener('click', function (e) {
      if (e.target.tagName !== 'IMG') close_();
    });

    var raf = 0;
    track.addEventListener('scroll', function () {
      if (raf) return;
      raf = requestAnimationFrame(function () {
        raf = 0;
        var w = track.clientWidth || 1;
        var i = Math.round(track.scrollLeft / w);
        if (i !== cur) { cur = i; setIdx(cur); }
      });
    });

    function go(i) {
      i = Math.max(0, Math.min(i, imgs.length - 1));
      track.scrollTo({ left: i * track.clientWidth, behavior: 'smooth' });
    }
    function onKey(e) {
      if (e.key === 'Escape') close_();
      else if (e.key === 'ArrowRight') go(cur + 1);
      else if (e.key === 'ArrowLeft') go(cur - 1);
    }
    document.addEventListener('keydown', onKey);

    scope.appendChild(root);
    /* 先无动画定位到起始页，再淡入 */
    requestAnimationFrame(function () {
      track.scrollLeft = start * track.clientWidth;
      void root.offsetWidth;
      root.classList.add('in');
    });

    return { close: close_, el: root };
  };

  /* ---- 自动接线：[data-lightbox] 容器内的图片成组 ---- */
  document.addEventListener('click', function (e) {
    if (!e.target.closest) return;
    var box = e.target.closest('[data-lightbox]');
    if (!box) return;
    var imgs = [].slice.call(box.querySelectorAll('img'));
    if (!imgs.length) return;
    var clicked = e.target.tagName === 'IMG' ? e.target : (e.target.closest('.ph, [data-lb-item]') || box).querySelector('img');
    var idx = clicked ? imgs.indexOf(clicked) : 0;
    e.preventDefault();
    DZ.lightbox({
      images: imgs.map(function (im) {
        return { src: im.getAttribute('src'), caption: im.getAttribute('data-caption') || '' };
      }),
      index: idx < 0 ? 0 : idx
    });
  });
})();
