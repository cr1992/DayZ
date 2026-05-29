/* DayZ 全局提示条（toast）引擎 —— 业务无关、零依赖。
   用法：DZ.toast('已保存到本地')
        DZ.toast({ text:'已移到回收站', tone:'danger', action:'撤销', onAction(){…} })
   选项：
     text      文案（必填；也可直接传字符串）
     tone      'default' | 'ok' | 'info' | 'danger' | 'fav'  —— 决定图标与点色
     variant   'dark'（默认，深色款） | 'surface'（表面款）
     icon      true(按 tone 取图标) | false(不要图标) | 自定义 SVG 字符串。默认：tone 非 default 时显示
     action    操作按钮文案（如 '撤销' / '查看' / '重试'）
     onAction  点操作的回调（点完即关闭）
     duration  毫秒；默认 2600，有 action 时 4200
     host      指定挂载容器（元素）；否则就近找 [data-toast-host] → .screen → body
   返回：{ dismiss() }
   Flutter 对应：ScaffoldMessenger.showSnackBar（behavior:floating）+ SnackBarAction。 */
(function () {
  var DZ = (window.DZ = window.DZ || {});
  var MAX = 3;        // 最多同时堆叠
  var EXIT = 240;     // 退场动画时长，需与 --dur 接近

  var ICON = {
    ok:     '<path d="M20 6 9 17l-5-5"/>',
    info:   '<circle cx="12" cy="12" r="9"/><path d="M12 11.5v4.5M12 7.7h.01"/>',
    danger: '<path d="M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h16.9a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/><path d="M12 9.5v4M12 17.2h.01"/>'
  };
  var STAR = '<path d="M12 2.5L14.47 8.6 21.04 9.06 16 13.3 17.58 19.69 12 16.2 6.42 19.69 8.01 13.3 2.97 9.06 9.53 8.6Z"/>';

  function svg(tone) {
    if (tone === 'fav') return '<svg viewBox="0 0 24 24" fill="currentColor">' + STAR + '</svg>';
    var inner = ICON[tone] || ICON.info;
    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' + inner + '</svg>';
  }

  function resolveHost(opts) {
    var scope = opts.host
      || document.querySelector('[data-toast-host]')
      || document.querySelector('.screen')
      || document.body;
    // 复用已有 host
    var existing = scope.querySelector(':scope > .toast-host');
    if (existing) return existing;
    var host = document.createElement('div');
    host.className = 'toast-host' + (opts.hostClass ? ' ' + opts.hostClass : '');
    if (scope === document.body) host.style.position = 'fixed';
    else if (getComputedStyle(scope).position === 'static') scope.style.position = 'relative';
    scope.appendChild(host);
    return host;
  }

  DZ.toast = function (opts) {
    if (typeof opts === 'string') opts = { text: opts };
    opts = opts || {};
    var tone = opts.tone || 'default';
    var host = resolveHost(opts);

    var el = document.createElement('div');
    el.className = 'toast' + (opts.variant === 'surface' ? ' surface' : '')
      + (tone === 'danger' ? ' danger' : '') + (tone === 'fav' ? ' fav' : '');

    var wantIcon = opts.icon === undefined ? (tone !== 'default') : !!opts.icon;
    if (wantIcon) {
      var ic = document.createElement('span');
      ic.className = 'ic';
      ic.innerHTML = typeof opts.icon === 'string' ? opts.icon : svg(tone);
      el.appendChild(ic);
    }
    var msg = document.createElement('span');
    msg.className = 'msg';
    msg.textContent = opts.text || '';
    el.appendChild(msg);

    var done;  // 前向声明
    if (opts.action) {
      var btn = document.createElement('button');
      btn.className = 'acc';
      btn.textContent = opts.action;
      btn.addEventListener('click', function (e) {
        e.stopPropagation();
        if (typeof opts.onAction === 'function') opts.onAction();
        done();
      });
      el.appendChild(btn);
    }

    // 超出上限：移除最早的
    var live = host.querySelectorAll('.toast:not(.out)');
    if (live.length >= MAX && live[0]._dismiss) live[0]._dismiss();

    host.appendChild(el);
    // 进场：强制一次回流提交初始态（opacity:0），再加 .in 触发过渡。
    // 不用 requestAnimationFrame —— 预览/后台态下 rAF 可能被节流不触发。
    void el.offsetWidth;
    el.classList.add('in');

    var timer = setTimeout(function () { done(); }, opts.duration || (opts.action ? 4200 : 2600));

    done = function () {
      if (el._closed) return; el._closed = true;
      clearTimeout(timer);
      el.classList.remove('in'); el.classList.add('out');
      setTimeout(function () { if (el.parentNode) el.parentNode.removeChild(el); }, EXIT);
    };
    el._dismiss = done;

    // 无操作按钮时，点击整条即关闭
    if (!opts.action) {
      el.style.cursor = 'pointer';
      el.addEventListener('click', function () { done(); });
    }

    return { dismiss: done };
  };
})();
