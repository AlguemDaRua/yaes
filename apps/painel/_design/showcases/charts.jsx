/* global React, YA */
const { Ico } = window.YA;

// ============== Helpers ==============
const BRAND = 'var(--brand)';
const BRAND_LINE = 'oklch(0.78 0.16 78)';
const GRID = 'var(--border-subtle)';
const AXIS = 'var(--text-muted)';

function ChartCard({ title, subtitle, children, height = 240, action, width }) {
  return (
    <div style={{
      background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)',
      borderRadius: 8, padding: 16, boxShadow: 'var(--shadow-sm)',
      display: 'flex', flexDirection: 'column', minWidth: 0,
      width,
    }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 12 }}>
        <div>
          <div style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)' }}>{title}</div>
          {subtitle && <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 2 }}>{subtitle}</div>}
        </div>
        {action}
      </div>
      <div style={{ height, position: 'relative' }}>{children}</div>
    </div>
  );
}

// ============== Sparkline ==============
function Sparkline({ data, width = 80, height = 28, color = BRAND_LINE, fill = false }) {
  const min = Math.min(...data), max = Math.max(...data);
  const range = max - min || 1;
  const points = data.map((v, i) => {
    const x = (i / (data.length - 1)) * width;
    const y = height - ((v - min) / range) * (height - 4) - 2;
    return [x, y];
  });
  const d = points.map((p, i) => (i === 0 ? `M ${p[0]} ${p[1]}` : `L ${p[0]} ${p[1]}`)).join(' ');
  const fillD = `${d} L ${width} ${height} L 0 ${height} Z`;
  return (
    <svg width={width} height={height} style={{ display: 'block', overflow: 'visible' }}>
      {fill && <path d={fillD} fill={color} fillOpacity={0.15} />}
      <path d={d} fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round" />
      <circle cx={points[points.length - 1][0]} cy={points[points.length - 1][1]} r={2} fill={color} />
    </svg>
  );
}

// ============== Line Chart ==============
function LineChart({ series, labels, width = 600, height = 220, yTicks = 4 }) {
  const padL = 44, padR = 16, padT = 8, padB = 28;
  const innerW = width - padL - padR;
  const innerH = height - padT - padB;
  const allValues = series.flatMap(s => s.data);
  const max = Math.max(...allValues);
  const min = 0;
  const range = max - min || 1;
  const xStep = innerW / (labels.length - 1);

  const yTickValues = Array.from({ length: yTicks + 1 }, (_, i) => min + (range * i / yTicks));

  return (
    <svg width="100%" height={height} viewBox={`0 0 ${width} ${height}`} preserveAspectRatio="none" style={{ overflow: 'visible' }}>
      {yTickValues.map((v, i) => {
        const y = padT + innerH - ((v - min) / range) * innerH;
        return (
          <g key={i}>
            <line x1={padL} y1={y} x2={width - padR} y2={y} stroke={GRID} strokeWidth={1} strokeDasharray={i === 0 ? '0' : '2 3'} />
            <text x={padL - 8} y={y + 3} fontSize={10} fill={AXIS} textAnchor="end" fontFamily="JetBrains Mono, monospace">{Math.round(v).toLocaleString('pt-PT')}</text>
          </g>
        );
      })}
      {labels.map((l, i) => {
        const x = padL + i * xStep;
        return <text key={i} x={x} y={height - 8} fontSize={10} fill={AXIS} textAnchor="middle">{l}</text>;
      })}
      {series.map((s, si) => {
        const points = s.data.map((v, i) => [padL + i * xStep, padT + innerH - ((v - min) / range) * innerH]);
        const d = points.map((p, i) => (i === 0 ? `M ${p[0]} ${p[1]}` : `L ${p[0]} ${p[1]}`)).join(' ');
        return (
          <g key={si}>
            <path d={d} fill="none" stroke={s.color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" strokeDasharray={s.dashed ? '4 4' : '0'} />
            {points.map((p, i) => <circle key={i} cx={p[0]} cy={p[1]} r={2.5} fill={s.color} />)}
          </g>
        );
      })}
    </svg>
  );
}

// ============== Area Chart ==============
function AreaChart({ data, labels, width = 600, height = 220, color = BRAND_LINE }) {
  const padL = 44, padR = 16, padT = 8, padB = 28;
  const innerW = width - padL - padR;
  const innerH = height - padT - padB;
  const max = Math.max(...data);
  const range = max || 1;
  const xStep = innerW / (data.length - 1);
  const points = data.map((v, i) => [padL + i * xStep, padT + innerH - (v / range) * innerH]);
  const d = points.map((p, i) => (i === 0 ? `M ${p[0]} ${p[1]}` : `L ${p[0]} ${p[1]}`)).join(' ');
  const fillD = `${d} L ${padL + (data.length - 1) * xStep} ${padT + innerH} L ${padL} ${padT + innerH} Z`;
  const yTicks = 4;
  const yTickValues = Array.from({ length: yTicks + 1 }, (_, i) => (max * i / yTicks));

  return (
    <svg width="100%" height={height} viewBox={`0 0 ${width} ${height}`} preserveAspectRatio="none">
      <defs>
        <linearGradient id="areaGrad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={color} stopOpacity={0.35} />
          <stop offset="100%" stopColor={color} stopOpacity={0.02} />
        </linearGradient>
      </defs>
      {yTickValues.map((v, i) => {
        const y = padT + innerH - (v / range) * innerH;
        return (
          <g key={i}>
            <line x1={padL} y1={y} x2={width - padR} y2={y} stroke={GRID} strokeWidth={1} strokeDasharray={i === 0 ? '0' : '2 3'} />
            <text x={padL - 8} y={y + 3} fontSize={10} fill={AXIS} textAnchor="end" fontFamily="JetBrains Mono, monospace">{Math.round(v / 1000)}k</text>
          </g>
        );
      })}
      {labels.map((l, i) => {
        if (i % Math.ceil(labels.length / 8) !== 0 && i !== labels.length - 1) return null;
        const x = padL + i * xStep;
        return <text key={i} x={x} y={height - 8} fontSize={10} fill={AXIS} textAnchor="middle">{l}</text>;
      })}
      <path d={fillD} fill="url(#areaGrad)" />
      <path d={d} fill="none" stroke={color} strokeWidth={2} />
    </svg>
  );
}

// ============== Bar Chart ==============
function BarChart({ data, labels, width = 600, height = 220, color = BRAND_LINE, stacked = false, secondary }) {
  const padL = 44, padR = 16, padT = 8, padB = 28;
  const innerW = width - padL - padR;
  const innerH = height - padT - padB;
  const totals = stacked ? data.map((v, i) => v + (secondary?.[i] || 0)) : data;
  const max = Math.max(...totals);
  const range = max || 1;
  const groupW = innerW / data.length;
  const barW = Math.min(groupW * 0.6, 36);
  const yTicks = 4;
  const yTickValues = Array.from({ length: yTicks + 1 }, (_, i) => (max * i / yTicks));

  return (
    <svg width="100%" height={height} viewBox={`0 0 ${width} ${height}`} preserveAspectRatio="none">
      {yTickValues.map((v, i) => {
        const y = padT + innerH - (v / range) * innerH;
        return (
          <g key={i}>
            <line x1={padL} y1={y} x2={width - padR} y2={y} stroke={GRID} strokeWidth={1} strokeDasharray={i === 0 ? '0' : '2 3'} />
            <text x={padL - 8} y={y + 3} fontSize={10} fill={AXIS} textAnchor="end" fontFamily="JetBrains Mono, monospace">{Math.round(v).toLocaleString('pt-PT')}</text>
          </g>
        );
      })}
      {data.map((v, i) => {
        const cx = padL + groupW * i + groupW / 2;
        const h1 = (v / range) * innerH;
        const y1 = padT + innerH - h1;
        const h2 = stacked && secondary ? (secondary[i] / range) * innerH : 0;
        const y2 = stacked && secondary ? y1 - h2 : 0;
        return (
          <g key={i}>
            <rect x={cx - barW / 2} y={y1} width={barW} height={h1} fill={color} rx={2} />
            {stacked && secondary && <rect x={cx - barW / 2} y={y2} width={barW} height={h2} fill="oklch(0.6 0.10 220)" rx={2} />}
            <text x={cx} y={height - 8} fontSize={10} fill={AXIS} textAnchor="middle">{labels[i]}</text>
          </g>
        );
      })}
    </svg>
  );
}

// ============== Donut Chart ==============
function DonutChart({ data, size = 200, thickness = 28, centerLabel, centerValue }) {
  const r = size / 2 - thickness / 2;
  const cx = size / 2, cy = size / 2;
  const total = data.reduce((s, d) => s + d.value, 0);
  let acc = 0;
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 24 }}>
      <svg width={size} height={size}>
        {data.map((d, i) => {
          const startAngle = (acc / total) * 2 * Math.PI - Math.PI / 2;
          acc += d.value;
          const endAngle = (acc / total) * 2 * Math.PI - Math.PI / 2;
          const x1 = cx + r * Math.cos(startAngle);
          const y1 = cy + r * Math.sin(startAngle);
          const x2 = cx + r * Math.cos(endAngle);
          const y2 = cy + r * Math.sin(endAngle);
          const largeArc = endAngle - startAngle > Math.PI ? 1 : 0;
          const path = `M ${x1} ${y1} A ${r} ${r} 0 ${largeArc} 1 ${x2} ${y2}`;
          return <path key={i} d={path} fill="none" stroke={d.color} strokeWidth={thickness} strokeLinecap="butt" />;
        })}
        {centerValue && (
          <>
            <text x={cx} y={cy - 4} fontSize={20} fontWeight={500} fill="var(--text-primary)" textAnchor="middle" fontFamily="Newsreader, serif">{centerValue}</text>
            <text x={cx} y={cy + 14} fontSize={10} fill="var(--text-muted)" textAnchor="middle" letterSpacing="0.05em" textTransform="uppercase">{centerLabel}</text>
          </>
        )}
      </svg>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {data.map((d, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ width: 10, height: 10, borderRadius: 2, background: d.color, flexShrink: 0 }} />
            <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{d.label}</span>
            <span className="ya-mono" style={{ fontSize: 12, color: 'var(--text-primary)', marginLeft: 'auto' }}>{Math.round((d.value / total) * 100)}%</span>
          </div>
        ))}
      </div>
    </div>
  );
}

// ============== Radial Gauge ==============
function RadialGauge({ value, max = 100, label, size = 200, color = BRAND_LINE, suffix = '%' }) {
  const r = size / 2 - 18;
  const cx = size / 2, cy = size / 2;
  const startAngle = Math.PI * 0.75;
  const endAngle = Math.PI * 2.25;
  const fullArc = endAngle - startAngle;
  const valueAngle = startAngle + (value / max) * fullArc;

  const arc = (start, end) => {
    const x1 = cx + r * Math.cos(start);
    const y1 = cy + r * Math.sin(start);
    const x2 = cx + r * Math.cos(end);
    const y2 = cy + r * Math.sin(end);
    const large = end - start > Math.PI ? 1 : 0;
    return `M ${x1} ${y1} A ${r} ${r} 0 ${large} 1 ${x2} ${y2}`;
  };

  return (
    <svg width={size} height={size * 0.85}>
      <path d={arc(startAngle, endAngle)} fill="none" stroke="var(--bg-subtle)" strokeWidth={14} strokeLinecap="round" />
      <path d={arc(startAngle, valueAngle)} fill="none" stroke={color} strokeWidth={14} strokeLinecap="round" />
      <text x={cx} y={cy + 4} fontSize={28} fontWeight={500} fill="var(--text-primary)" textAnchor="middle" fontFamily="Newsreader, serif">{value}<tspan fontSize={14} fill="var(--text-secondary)">{suffix}</tspan></text>
      <text x={cx} y={cy + 28} fontSize={11} fill="var(--text-muted)" textAnchor="middle" letterSpacing="0.05em">{label}</text>
    </svg>
  );
}

// ============== Showcase ==============
function ChartsShowcase() {
  const sectionTitle = { fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, margin: '0 0 14px' };

  const months = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
  const dailyLabels = ['1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27','28','29','30'];
  const tripsThisMonth = [820, 910, 880, 1020, 1180, 1240, 1340, 1280, 1420, 1380, 1480, 1520, 1580, 1620, 1680, 1740, 1810, 1880, 1920, 1980, 2040, 2120, 2180, 2240, 2310, 2380, 2440, 2510, 2580, 2650];
  const tripsLastMonth = [780, 850, 820, 940, 1080, 1140, 1240, 1180, 1310, 1280, 1350, 1380, 1450, 1490, 1530, 1580, 1630, 1690, 1740, 1780, 1820, 1880, 1930, 1980, 2040, 2090, 2140, 2200, 2240, 2290];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
      <section>
        <h3 style={sectionTitle}>Sparklines — inline em KPIs e tabelas</h3>
        <div style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)', borderRadius: 8, padding: 16, display: 'flex', gap: 32, flexWrap: 'wrap' }}>
          {[
            { label: 'Corridas hoje', value: '2.847', data: [120, 145, 132, 168, 175, 192, 210, 235, 248], color: BRAND_LINE, fill: true },
            { label: 'GMV semanal', value: '4.2M MZN', data: [500, 540, 580, 620, 590, 640, 720], color: 'var(--success)' },
            { label: 'Cancelamento', value: '3.4%', data: [4.2, 4.0, 3.8, 3.6, 3.5, 3.4, 3.4], color: 'var(--success)' },
            { label: 'Tempo médio', value: '12.4 min', data: [11.0, 11.4, 11.8, 12.0, 12.2, 12.3, 12.4], color: 'var(--warning)' },
          ].map((m, i) => (
            <div key={i} style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
              <div style={{ fontSize: 10, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>{m.label}</div>
              <div style={{ fontSize: 22, fontWeight: 500, fontFamily: 'Newsreader, serif', color: 'var(--text-primary)' }}>{m.value}</div>
              <Sparkline data={m.data} color={m.color} fill={m.fill} width={120} height={32} />
            </div>
          ))}
        </div>
      </section>

      <section>
        <h3 style={sectionTitle}>Line Chart — comparativo mês a mês</h3>
        <ChartCard
          title="Corridas diárias · este mês vs anterior"
          subtitle="Linha cheia = Maio · linha tracejada = Abril"
          height={260}
          action={
            <div style={{ display: 'flex', gap: 12, fontSize: 11, color: 'var(--text-secondary)' }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}><span style={{ width: 12, height: 2, background: BRAND_LINE }} />Maio</span>
              <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}><span style={{ width: 12, height: 2, background: 'var(--text-muted)' }} />Abril</span>
            </div>
          }
        >
          <LineChart
            labels={['1','5','10','15','20','25','30']}
            series={[
              { color: BRAND_LINE, data: [820, 1180, 1380, 1620, 1980, 2310, 2650] },
              { color: 'var(--text-muted)', dashed: true, data: [780, 1080, 1280, 1490, 1780, 2040, 2290] },
            ]}
            height={220}
          />
        </ChartCard>
      </section>

      <section>
        <h3 style={sectionTitle}>Area Chart — GMV mensal acumulado</h3>
        <ChartCard title="GMV (MZN) · últimos 12 meses" subtitle="Total: 38.4M MZN · +18.2% YoY" height={260}>
          <AreaChart
            labels={months}
            data={[2100000, 2240000, 2380000, 2520000, 2680000, 2840000, 3010000, 3180000, 3340000, 3510000, 3680000, 3850000]}
            color={BRAND_LINE}
            height={220}
          />
        </ChartCard>
      </section>

      <section>
        <h3 style={sectionTitle}>Bar Charts — empilhado e simples</h3>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <ChartCard title="Corridas por dia da semana · empilhado" subtitle="Dourado = pago app · azul = dinheiro" height={240}>
            <BarChart
              labels={['Seg','Ter','Qua','Qui','Sex','Sáb','Dom']}
              data={[420, 480, 510, 520, 680, 740, 580]}
              secondary={[180, 210, 220, 240, 320, 380, 280]}
              stacked
              color={BRAND_LINE}
              height={200}
            />
          </ChartCard>
          <ChartCard title="Top 8 partners · corridas no mês" subtitle="Maputo Executive lidera" height={240}>
            <BarChart
              labels={['MEX','BMB','NPT','PEM','TET','GZA','XAI','MAN']}
              data={[2840, 1920, 1480, 1240, 980, 820, 680, 540]}
              color={BRAND_LINE}
              height={200}
            />
          </ChartCard>
        </div>
      </section>

      <section>
        <h3 style={sectionTitle}>Donut Chart — distribuição por estado</h3>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <ChartCard title="Drivers por estado" subtitle="Total: 1 247" height={240}>
            <DonutChart
              size={180}
              centerLabel="Drivers"
              centerValue="1 247"
              data={[
                { label: 'Online', value: 847, color: 'var(--success)' },
                { label: 'Offline', value: 328, color: 'var(--text-muted)' },
                { label: 'Pendentes', value: 47, color: 'var(--warning)' },
                { label: 'Suspensos', value: 25, color: 'var(--danger)' },
              ]}
            />
          </ChartCard>
          <ChartCard title="Receita por método de pagamento" subtitle="Maio · 4.2M MZN" height={240}>
            <DonutChart
              size={180}
              centerLabel="Total"
              centerValue="4.2M"
              data={[
                { label: 'M-Pesa', value: 2400, color: BRAND_LINE },
                { label: 'Cartão', value: 1100, color: 'oklch(0.6 0.10 220)' },
                { label: 'Dinheiro', value: 580, color: 'var(--text-muted)' },
                { label: 'eMola', value: 120, color: 'var(--success)' },
              ]}
            />
          </ChartCard>
        </div>
      </section>

      <section>
        <h3 style={sectionTitle}>Radial Gauge — KPIs com meta</h3>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
          <ChartCard title="SLA de tickets" subtitle="Meta: 95%" height={200}>
            <div style={{ display: 'flex', justifyContent: 'center' }}>
              <RadialGauge value={97} label="Resolvidos a tempo" color="var(--success)" />
            </div>
          </ChartCard>
          <ChartCard title="Conformidade documental" subtitle="Meta: 90%" height={200}>
            <div style={{ display: 'flex', justifyContent: 'center' }}>
              <RadialGauge value={84} label="Drivers em dia" color="var(--warning)" />
            </div>
          </ChartCard>
          <ChartCard title="Aceitação de corridas" subtitle="Meta: 85%" height={200}>
            <div style={{ display: 'flex', justifyContent: 'center' }}>
              <RadialGauge value={92} label="Aceites" color={BRAND_LINE} />
            </div>
          </ChartCard>
          <ChartCard title="Cancelamento" subtitle="Limite: <5%" height={200}>
            <div style={{ display: 'flex', justifyContent: 'center' }}>
              <RadialGauge value={3.4} max={10} label="Taxa actual" color="var(--success)" suffix="%" />
            </div>
          </ChartCard>
        </div>
      </section>
    </div>
  );
}

window.ChartsShowcase = ChartsShowcase;
window.YA_Sparkline = Sparkline;
