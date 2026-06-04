/* 底部弹层（sheet）引擎 —— 业务无关、零依赖。
   动作菜单 / 选择器 / 轻表单三合一。从底部滑入，scrim 点击关闭。

   用法：
     // 1) 动作菜单
     DZ.sheet({ title:'更多', items:[
       { label:'编辑', icon:'<svg…>', onTap(){…} },
       { label:'删除', icon:'<svg…>', tone:'danger', onTap(){…} },
     ]});
     // 2) 单选选择器（selected 命中项右侧打勾）
     DZ.sheet({ title:'主题色', items:[
       { label:'雾紫', swatch:'#786CAD', selected:true, onTap(){…} }, …
     ]});
     // 3) 轻表单（自定义内容 + 主按钮）
     DZ.sheet({ title:'新建项目', content: el, primary:{ label:'创建', onTap(){…} } });

   item 字段：label / desc(次级行) / icon(SVG 串) / swatch(色点) / tone('danger')
              / selected(打勾) / keepOpen(点后不自动关) / onTap(回调)
   顶层字段：title / desc / items[] / content(节点或 HTML) / primary{label,onTap,disabled}
              / cancel(取消文案，默认 '取消'；传 null 隐藏) / host(挂载容器)
   返回：{ close() }
   Flutter 对应：showModalBottomSheet（圆角顶 + 拖拽柄 + SafeArea 底部留白）。 */
(function () {
  var DZ = (window.DZ = window.DZ || {});
  var EXIT = 260;
  var CHECK = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>';

  function host(opts) {
    return opts.host || document.querySelector('.pg') || document.querySelector('.screen') || document.body;
  }

  DZ.sheet = function (opts) {
    opts = opts || {};
    var scope = host(opts);
    if (getComputedStyle(scope).position === 'static') scope.style.position = 'relative';

    var scrim = document.createElement('div');
    scrim.className = 'sheet-scrim';
    var sheet = document.createElement('div');
    sheet.className = 'sheet';
    sheet.setAttribute('role', 'dialog');
    sheet.setAttribute('aria-modal', 'true');

    var html = '<div class="sheet-grip"></div>';
    if (opts.title || opts.desc) {
      html += '<div class="sheet-head">' +
        (opts.title ? '<div class="t">' + opts.title + '</div>' : '') +
        (opts.desc ? '<div class="d">' + opts.desc + '</div>' : '') + '</div>';
    }
    sheet.innerHTML = html;

    var closed = false;
    function close() {
      if (closed) return; closed = true;
      scrim.classList.remove('in'); scrim.classList.add('out');
      sheet.classList.remove('in'); sheet.classList.add('out');
      setTimeout(function () {
        if (scrim.parentNode) scrim.parentNode.removeChild(scrim);
        if (sheet.parentNode) sheet.parentNode.removeChild(sheet);
      }, EXIT);
      if (typeof opts.onClose === 'function') opts.onClose();
    }

    /* 自定义内容（表单等）*/
    if (opts.content) {
      var body = document.createElement('div');
      body.className = 'sheet-body';
      if (typeof opts.content === 'string') body.innerHTML = opts.content;
      else body.appendChild(opts.content);
      sheet.appendChild(body);
    }

    /* 动作 / 选择列表 */
    if (opts.items && opts.items.length) {
      var list = document.createElement('div');
      list.className = 'sheet-list';
      opts.items.forEach(function (it) {
        if (it.sep) { var s = document.createElement('div'); s.className = 'sheet-sep'; list.appendChild(s); return; }
        var b = document.createElement('button');
        b.className = 'sheet-item' + (it.tone === 'danger' ? ' danger' : '') + (it.selected ? ' sel' : '');
        var inner = '';
        if (it.swatch) inner += '<span class="sw" style="background:' + it.swatch + '"></span>';
        else if (it.icon) inner += '<span class="ic">' + it.icon + '</span>';
        inner += '<span class="tx"><b>' + (it.label || '') + '</b>' + (it.desc ? '<span>' + it.desc + '</span>' : '') + '</span>';
        inner += '<span class="chk">' + CHECK + '</span>';
        b.innerHTML = inner;
        b.addEventListener('click', function () {
          if (typeof it.onTap === 'function') it.onTap();
          if (!it.keepOpen) close();
        });
        list.appendChild(b);
      });
      sheet.appendChild(list);
    }

    /* 主 / 次按钮（表单提交）*/
    if (opts.primary || opts.secondary) {
      var foot = document.createElement('div');
      foot.className = 'sheet-foot';
      if (opts.primary) {
        var p = document.createElement('button');
        p.className = 'btn btn-primary btn-lg';
        p.textContent = opts.primary.label || '确定';
        if (opts.primary.disabled) p.disabled = true;
        p._primary = opts.primary;
        p.addEventListener('click', function () {
          if (p.disabled) return;
          var keep = opts.primary.onTap && opts.primary.onTap() === false;
          if (!keep) close();
        });
        foot.appendChild(p);
        sheet._primaryBtn = p;
      }
      if (opts.secondary) {
        var sc = document.createElement('button');
        sc.className = 'btn btn-ghost btn-lg';
        sc.textContent = opts.secondary.label || '取消';
        sc.addEventListener('click', function () {
          if (typeof opts.secondary.onTap === 'function') opts.secondary.onTap();
          close();
        });
        foot.appendChild(sc);
      }
      sheet.appendChild(foot);
    }

    /* 取消行（动作菜单默认有；表单默认无）*/
    var wantCancel = opts.cancel === undefined ? (!!opts.items && !opts.primary) : (opts.cancel !== null && opts.cancel !== false);
    if (wantCancel) {
      var c = document.createElement('button');
      c.className = 'sheet-cancel';
      c.textContent = typeof opts.cancel === 'string' ? opts.cancel : '取消';
      c.addEventListener('click', close);
      sheet.appendChild(c);
    }

    scope.appendChild(scrim);
    scope.appendChild(sheet);
    scrim.addEventListener('click', close);

    /* 进场：强制回流提交初始态，再加 .in（与 toast 同理，避免 rAF 被节流）*/
    void sheet.offsetWidth;
    scrim.classList.add('in');
    sheet.classList.add('in');

    return { close: close, el: sheet };
  };

  /* 便捷封装：确认再执行（最常见的 sheet 特化）。
     DZ.confirm({ title:'删除这一项？', desc:'…', confirmLabel:'移到回收站', icon:'<svg…>', danger:true, onConfirm(){…} })
     danger 默认 true（确认多为危险操作）；传 danger:false 用普通色。 */
  DZ.confirm = function (opts) {
    opts = opts || {};
    return DZ.sheet({
      title: opts.title || "确认操作？",
      desc: opts.desc,
      items: [{
        label: opts.confirmLabel || "确认",
        icon: opts.icon,
        tone: opts.danger === false ? undefined : "danger",
        onTap: opts.onConfirm
      }],
      cancel: opts.cancel === undefined ? "取消" : opts.cancel
    });
  };
})();
