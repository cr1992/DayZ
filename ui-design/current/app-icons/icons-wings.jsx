/* DayZ — App Icon · 开卷成翼（定向方案）
   方向已定：摊开的两页 = 一对翅膀。呼应「记忆起飞 / 往年今日」。
   三个子变体供定稿：① 平展 ② 上扬 ③ 羽毛边。
   每种 暖纸底(描边) + 实色底(填白) 并排；附三主题色 + 小尺寸识别。 */

const WTHEMES = {
  purple: { accent: '#786CAD', strong: '#635693', onAccent: '#FFFFFF', ink: '#564A86', soft: '#EEEBF6', name: '雾紫 Lavender' },
  amber:  { accent: '#C8993E', strong: '#AE8129', onAccent: '#3A2C0C', ink: '#876012', soft: '#FAF1DB', name: '暖黄 Honey' },
  sage:   { accent: '#5C8A68', strong: '#4A7455', onAccent: '#FFFFFF', ink: '#3C6048', soft: '#E6F0E8', name: '雾绿 Sage' },
};
const WPAPER = { bg: '#FAF7F1', surface: '#FFFFFF', ink: '#2C2823', hair: '#E7DFD2' };

function wmix(a, b, pct){ return `color-mix(in oklab, ${a}, ${b} ${pct}%)`; }
const wSolidBg = (t) => `linear-gradient(157deg, ${wmix(t.accent,'#ffffff',16)} 0%, ${t.accent} 56%, ${t.strong} 100%)`;
const wPaperBg = () => `linear-gradient(157deg, #FFFFFF 0%, ${WPAPER.bg} 70%, #F4EFE6 100%)`;

/* ---- iOS squircle shell ---------------------------------------- */
function WSquircle({ size, children, surface, ring, flat }) {
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

/* =================================================================
   开卷成翼 — 右翼路径（闭合轮廓），左翼镜像
   shape: 'flat' 平展 | 'lift' 上扬 | 'feather' 羽毛边
   ================================================================= */
const WING_R = {
  flat:    'M50 40 C 61 32 74 32 86 39 C 80 46 78 54 80 62 C 68 56 57 57 50 62 Z',
  lift:    'M50 44 C 60 30 76 26 89 31 C 83 40 81 50 82 61 C 69 55 57 57 50 61 Z',
  feather: 'M50 42 C 61 33 73 32 85 38 Q 81 45 80 53 Q 73 51 70 56 Q 64 54 59 58 Q 54 57 50 61 Z',
};
const SPINE = { flat: [40,72], lift: [42,72], feather: [40,72] };

function OpenWing({ size, shape, accent, onAccent, solid }) {
  const d = WING_R[shape];
  const [sy0, sy1] = SPINE[shape];
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" style={{ display:'block' }}>
      {solid ? (
        <>
          <path d={d} fill={onAccent} stroke={onAccent} strokeWidth="1.5" strokeLinejoin="round" />
          <g transform="translate(100,0) scale(-1,1)">
            <path d={d} fill={onAccent} stroke={onAccent} strokeWidth="1.5" strokeLinejoin="round" />
          </g>
          <line x1="50" y1={sy0-1} x2="50" y2={sy1} stroke={accent} strokeWidth="3.4" strokeLinecap="round" />
        </>
      ) : (
        <g fill="none" stroke={accent} strokeWidth="5" strokeLinecap="round" strokeLinejoin="round">
          <path d={d} />
          <g transform="translate(100,0) scale(-1,1)"><path d={d} /></g>
          <line x1="50" y1={sy0} x2="50" y2={sy1} />
        </g>
      )}
    </svg>
  );
}

/* =================================================================
   子变体清单
   ================================================================= */
const WCONCEPTS = [
  {
    id: 'flat', shape: 'flat', name: '① 平展', tag: '摊开的两页 · 安稳',
    note: '最贴近真实摊开的书：两页平稳展开，弧度温和。安静、内敛，像一本静静摊开的日记。',
  },
  {
    id: 'lift', shape: 'lift', name: '② 上扬', tag: '翼尖上扬 · 飞翔感',
    note: '翼尖抬高到书脊之上，更有「展翅起飞」的动势。呼应记忆起飞 / 往年今日，意象最足。',
  },
  {
    id: 'feather', shape: 'feather', name: '③ 羽毛边', tag: '下缘扇贝 · 更像翅膀',
    note: '把页缘做成三段羽毛扇贝，「翅膀」属性最强、最一眼能认。小尺寸下细节会略收敛。',
  },
];

/* ---- card per concept ------------------------------------------ */
function WConceptCard({ c }) {
  const t = WTHEMES.purple;
  const paper = (th, size) => (
    <WSquircle size={size} surface={wPaperBg()} flat ring={WPAPER.hair}>
      <OpenWing size={size} shape={c.shape} accent={th.accent} onAccent={th.onAccent} />
    </WSquircle>
  );
  const solid = (th, size) => (
    <WSquircle size={size} surface={wSolidBg(th)} ring="rgba(255,255,255,0.18)">
      <OpenWing size={size} shape={c.shape} accent={th.accent} onAccent={th.onAccent} solid />
    </WSquircle>
  );
  return (
    <div style={{ display:'flex', flexDirection:'column', gap:18, padding:'26px 24px 24px',
      height:'100%', boxSizing:'border-box' }}>
      <div style={{ display:'flex', flexDirection:'column', gap:4 }}>
        <div style={{ fontFamily:'Newsreader, serif', fontSize:22, fontWeight:600, color:WPAPER.ink }}>{c.name}</div>
        <div style={{ fontFamily:'"Hanken Grotesk", sans-serif', fontSize:12.5, letterSpacing:'0.06em',
          textTransform:'uppercase', color:t.ink }}>{c.tag}</div>
      </div>

      <div style={{ display:'flex', justifyContent:'center', gap:18, padding:'6px 0 2px' }}>
        <div style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:8 }}>
          {paper(t, 148)}
          <span style={{ fontFamily:'"Hanken Grotesk", sans-serif', fontSize:10.5, color:'#9C958A' }}>暖纸底</span>
        </div>
        <div style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:8 }}>
          {solid(t, 148)}
          <span style={{ fontFamily:'"Hanken Grotesk", sans-serif', fontSize:10.5, color:'#9C958A' }}>实色底</span>
        </div>
      </div>

      <div style={{ display:'flex', flexDirection:'column', gap:8 }}>
        <div style={{ fontFamily:'"Hanken Grotesk", sans-serif', fontSize:11, color:'#9C958A',
          letterSpacing:'0.04em' }}>三套主题色（实色底）</div>
        <div style={{ display:'flex', gap:16, justifyContent:'space-between' }}>
          {['purple','amber','sage'].map(k => (
            <div key={k} style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:7 }}>
              {solid(WTHEMES[k], 72)}
              <span style={{ fontFamily:'"Hanken Grotesk", sans-serif', fontSize:10.5, color:'#9C958A' }}>
                {WTHEMES[k].name.split(' ')[0]}
              </span>
            </div>
          ))}
        </div>
      </div>

      <div style={{ display:'flex', flexDirection:'column', gap:8 }}>
        <div style={{ fontFamily:'"Hanken Grotesk", sans-serif', fontSize:11, color:'#9C958A',
          letterSpacing:'0.04em' }}>小尺寸识别</div>
        <div style={{ display:'flex', gap:16, alignItems:'flex-end' }}>
          {[58, 40, 29].map(s => (
            <div key={s} style={{ display:'flex', gap:8 }}>
              {paper(t, s)}
              {solid(t, s)}
            </div>
          ))}
        </div>
      </div>

      <p style={{ margin:0, fontFamily:'Newsreader, serif', fontSize:14, lineHeight:1.7,
        color:'#6A6359', marginTop:'auto' }}>{c.note}</p>
    </div>
  );
}

/* ---- homescreen preview ---------------------------------------- */
function WHomescreen() {
  const tiles = [
    ['flat','purple'], ['lift','purple'], ['feather','purple'],
    ['lift','amber'], ['lift','sage'], ['lift','purple'],
  ];
  const solid = (shape, th, size) => (
    <WSquircle size={size} surface={wSolidBg(th)} ring="rgba(255,255,255,0.18)">
      <OpenWing size={size} shape={shape} accent={th.accent} onAccent={th.onAccent} solid />
    </WSquircle>
  );
  return (
    <div style={{ width:'100%', height:'100%', boxSizing:'border-box',
      background:'linear-gradient(165deg, #2B2740 0%, #3A3052 45%, #4A3F4A 100%)',
      padding:'40px 30px', display:'flex', flexDirection:'column' }}>
      <div style={{ display:'grid', gridTemplateColumns:'repeat(3, 1fr)', gap:'26px 22px', justifyItems:'center' }}>
        {tiles.map(([shape, th], i) => (
          <div key={i} style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:8 }}>
            {solid(shape, WTHEMES[th], 66)}
            <span style={{ fontFamily:'"Hanken Grotesk", sans-serif', fontSize:12,
              color:'rgba(255,255,255,0.92)', textShadow:'0 1px 3px rgba(0,0,0,0.4)' }}>DayZ</span>
          </div>
        ))}
      </div>
      <div style={{ marginTop:'auto', textAlign:'center', fontFamily:'"Hanken Grotesk", sans-serif',
        fontSize:12, color:'rgba(255,255,255,0.5)', paddingTop:24 }}>
        开卷成翼 — 三个子变体 · 实色底 · 三主题色
      </div>
    </div>
  );
}

/* ---- mount ------------------------------------------------------ */
function App() {
  return (
    <DesignCanvas>
      <DCSection id="wings" title="DayZ · 开卷成翼" subtitle="方向已定 · 摊开的两页 = 一对翅膀 · 三个子变体定稿">
        {WCONCEPTS.map(c => (
          <DCArtboard key={c.id} id={c.id} label={c.name} width={380} height={640}>
            <div style={{ width:'100%', height:'100%', background:WPAPER.surface }}>
              <WConceptCard c={c} />
            </div>
          </DCArtboard>
        ))}
      </DCSection>
      <DCSection id="home" title="桌面预览" subtitle="放到 iOS 主屏上的实际观感">
        <DCArtboard id="homescreen" label="主屏 · 开卷成翼 × 主题色" width={390} height={540}>
          <WHomescreen />
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
