/* DayZ — App Icon · 方案 B（书签线描本）两种底对比
   B·实色底（主题实色 + 奶白描边）  ·  B·暖纸底（A 风格：暖纸 + 强调色描边）
   附 A·净（无书签）做参照 */

const THEMES = {
  purple: { accent: '#786CAD', strong: '#635693', onAccent: '#FFFFFF', ink: '#564A86', soft: '#EEEBF6', name: '雾紫 Lavender' },
  amber:  { accent: '#C8993E', strong: '#AE8129', onAccent: '#3A2C0C', ink: '#876012', soft: '#FAF1DB', name: '暖黄 Honey' },
  sage:   { accent: '#5C8A68', strong: '#4A7455', onAccent: '#FFFFFF', ink: '#3C6048', soft: '#E6F0E8', name: '雾绿 Sage' },
};
const PAPER = { bg: '#FAF7F1', surface: '#FFFFFF', ink: '#2C2823', hair: '#E7DFD2' };

function mix(a, b, pct){ return `color-mix(in oklab, ${a}, ${b} ${pct}%)`; }
const solidBg = (t) => `linear-gradient(157deg, ${mix(t.accent,'#ffffff',16)} 0%, ${t.accent} 56%, ${t.strong} 100%)`;
const paperBg = () => `linear-gradient(157deg, #FFFFFF 0%, ${PAPER.bg} 70%, #F4EFE6 100%)`;

/* ---- iOS squircle shell ---------------------------------------- */
function Squircle({ size, children, surface, ring, flat }) {
  const r = size * 0.2237;
  return (
    <div style={{
      width: size, height: size, borderRadius: r, position: 'relative',
      background: surface, overflow: 'hidden', flexShrink: 0,
      boxShadow: flat
        ? `inset 0 0 0 1px rgba(0,0,0,0.05)`
        : `0 ${size*0.035}px ${size*0.09}px rgba(60,50,35,0.20), 0 ${size*0.008}px ${size*0.02}px rgba(60,50,35,0.12)`,
    }}>
      <div style={{ position:'absolute', inset:0, borderRadius:r,
        background:'linear-gradient(160deg, rgba(255,255,255,0.22), rgba(255,255,255,0) 42%)', pointerEvents:'none' }} />
      <div style={{ position:'absolute', inset:0, borderRadius:r,
        boxShadow:`inset 0 0 0 1px ${ring||'rgba(0,0,0,0.06)'}`, pointerEvents:'none' }} />
      <div style={{ position:'absolute', inset:0, display:'flex', alignItems:'center', justifyContent:'center' }}>
        {children}
      </div>
    </div>
  );
}

/* shared notebook artwork (line + optional bookmark) */
function Notebook({ size, stroke, bookmark }) {
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" style={{ display:'block' }}>
      <g fill="none" stroke={stroke} strokeWidth="5" strokeLinecap="round" strokeLinejoin="round">
        <rect x="29" y="22" width="42" height="56" rx="8" />
        <line x1="40" y1="24" x2="40" y2="76" />
      </g>
      {bookmark && <path d="M54 24 h10 v15 l-5 -4.2 l-5 4.2 Z" fill={bookmark} />}
    </svg>
  );
}

/* ---- the concepts ---------------------------------------------- */
const CONCEPTS = [
  {
    id: 'solid', name: 'B · 实色底', tag: '主题实色 · 奶白描边',
    note: '实色封面 + 奶白描边 + 奶白书签。对比强、最“显眼”，放主屏一眼抓得住。',
    render: (t, size) => (
      <Squircle size={size} surface={solidBg(t)} ring="rgba(255,255,255,0.18)">
        <Notebook size={size} stroke={t.onAccent} bookmark={t.onAccent} />
      </Squircle>
    ),
  },
  {
    id: 'paperb', name: 'B · 暖纸底', tag: 'A 风格 · 强调色描边 + 书签',
    note: '把书签本放进 A 的暖纸效果：暖白纸 + 强调色描边 + 同色书签做焦点。更安静、更纸感，书签是唯一的彩色点。',
    render: (t, size) => (
      <Squircle size={size} surface={paperBg()} flat ring={PAPER.hair}>
        <Notebook size={size} stroke={t.accent} bookmark={t.accent} />
      </Squircle>
    ),
  },
  {
    id: 'clean', name: 'A · 净（参照）', tag: '暖纸 · 无书签',
    note: '最初的 A：暖纸 + 描边，连书签都没有。放这里做参照，方便看“加不加书签”的差别。',
    render: (t, size) => (
      <Squircle size={size} surface={paperBg()} flat ring={PAPER.hair}>
        <Notebook size={size} stroke={t.accent} bookmark={null} />
      </Squircle>
    ),
  },
];

/* ---- card per concept ------------------------------------------ */
function ConceptCard({ c }) {
  const t = THEMES.purple;
  return (
    <div style={{ display:'flex', flexDirection:'column', gap:18, padding:'26px 24px 24px',
      height:'100%', boxSizing:'border-box' }}>
      <div style={{ display:'flex', flexDirection:'column', gap:4 }}>
        <div style={{ fontFamily:'Newsreader, serif', fontSize:22, fontWeight:600, color:PAPER.ink }}>{c.name}</div>
        <div style={{ fontFamily:'"Hanken Grotesk", sans-serif', fontSize:12.5, letterSpacing:'0.06em',
          textTransform:'uppercase', color:t.ink }}>{c.tag}</div>
      </div>

      <div style={{ display:'flex', justifyContent:'center', padding:'8px 0 4px' }}>
        {c.render(t, 168)}
      </div>

      <div style={{ display:'flex', flexDirection:'column', gap:8 }}>
        <div style={{ fontFamily:'"Hanken Grotesk", sans-serif', fontSize:11, color:'#9C958A',
          letterSpacing:'0.04em' }}>三套主题色</div>
        <div style={{ display:'flex', gap:16, justifyContent:'space-between' }}>
          {['purple','amber','sage'].map(k => (
            <div key={k} style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:7 }}>
              {c.render(THEMES[k], 72)}
              <span style={{ fontFamily:'"Hanken Grotesk", sans-serif', fontSize:10.5, color:'#9C958A' }}>
                {THEMES[k].name.split(' ')[0]}
              </span>
            </div>
          ))}
        </div>
      </div>

      <div style={{ display:'flex', flexDirection:'column', gap:8 }}>
        <div style={{ fontFamily:'"Hanken Grotesk", sans-serif', fontSize:11, color:'#9C958A',
          letterSpacing:'0.04em' }}>小尺寸识别</div>
        <div style={{ display:'flex', gap:14, alignItems:'flex-end' }}>
          {[58, 40, 29].map(s => (
            <div key={s} style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:6 }}>
              {c.render(t, s)}
              <span style={{ fontFamily:'"Hanken Grotesk", sans-serif', fontSize:9.5, color:'#B8B0A2' }}>{s}px</span>
            </div>
          ))}
        </div>
      </div>

      <p style={{ margin:0, fontFamily:'Newsreader, serif', fontSize:14, lineHeight:1.7,
        color:'#6A6359', marginTop:'auto' }}>{c.note}</p>
    </div>
  );
}

/* ---- homescreen preview (the two B grounds × 3 themes) --------- */
function Homescreen() {
  const tiles = [
    ['solid','purple'], ['solid','amber'], ['solid','sage'],
    ['paperb','purple'], ['paperb','amber'], ['paperb','sage'],
  ];
  return (
    <div style={{ width:'100%', height:'100%', boxSizing:'border-box',
      background:'linear-gradient(165deg, #2B2740 0%, #3A3052 45%, #4A3F4A 100%)',
      padding:'40px 30px', display:'flex', flexDirection:'column' }}>
      <div style={{ display:'grid', gridTemplateColumns:'repeat(3, 1fr)', gap:'26px 22px', justifyItems:'center' }}>
        {tiles.map(([id, th], i) => {
          const c = CONCEPTS.find(x => x.id === id);
          return (
            <div key={i} style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:8 }}>
              {c.render(THEMES[th], 66)}
              <span style={{ fontFamily:'"Hanken Grotesk", sans-serif', fontSize:12,
                color:'rgba(255,255,255,0.92)', textShadow:'0 1px 3px rgba(0,0,0,0.4)' }}>DayZ</span>
            </div>
          );
        })}
      </div>
      <div style={{ marginTop:'auto', textAlign:'center', fontFamily:'"Hanken Grotesk", sans-serif',
        fontSize:12, color:'rgba(255,255,255,0.5)', paddingTop:24 }}>
        上排 B · 实色底　·　下排 B · 暖纸底　—　各三主题色
      </div>
    </div>
  );
}

/* ---- mount ------------------------------------------------------ */
function App() {
  return (
    <DesignCanvas>
      <DCSection id="concepts" title="DayZ · 日记本图标 B" subtitle="书签线描本 · 实色底 vs 暖纸底（A 风格）对比">
        {CONCEPTS.map(c => (
          <DCArtboard key={c.id} id={c.id} label={c.name} width={360} height={600}>
            <div style={{ width:'100%', height:'100%', background:PAPER.surface }}>
              <ConceptCard c={c} />
            </div>
          </DCArtboard>
        ))}
      </DCSection>
      <DCSection id="home" title="桌面预览" subtitle="两种底放到 iOS 主屏上的实际观感">
        <DCArtboard id="homescreen" label="主屏 · 实色 vs 暖纸 × 三主题" width={390} height={540}>
          <Homescreen />
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
