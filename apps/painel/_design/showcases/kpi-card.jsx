/* global React, YA */
const { Ico } = window.YA;

function KpiCard({ label, value, suffix, trend, icon, variant = 'default', loading = false, empty = false, hover = false, onTap = false }) {
  const border = variant === 'highlighted' ? '1.5px solid var(--brand-border)' : '1px solid var(--border-subtle)';
  const bg = hover ? 'var(--bg-elevated)' : 'var(--bg-surface)';

  if (loading) {
    return (
      <div style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)', borderRadius: 8, padding: '13px 16px 14px', boxShadow: 'var(--shadow-sm)' }}>
        <div className="ya-skeleton" style={{ width: 60, height: 11, marginBottom: 12 }} />
        <div className="ya-skeleton" style={{ width: 110, height: 26, marginBottom: 10 }} />
        <div className="ya-skeleton" style={{ width: 80, height: 11 }} />
      </div>
    );
  }

  const trendColor = trend ? `var(--${trend.semantic === 'positive' ? 'success' : trend.semantic === 'negative' ? 'danger' : 'neutral'})` : null;
  const TrendIco = trend ? (trend.direction === 'up' ? Ico.Up : trend.direction === 'down' ? Ico.Down : Ico.Flat) : null;

  return (
    <div style={{
      background: bg, border, borderRadius: 8,
      padding: '13px 16px 14px',
      boxShadow: 'var(--shadow-sm)',
      cursor: onTap ? 'pointer' : 'default',
      transition: 'background 150ms ease-out, border-color 150ms',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
        <span style={{ fontSize: 10.5, letterSpacing: '0.06em', color: 'var(--text-secondary)', fontWeight: 500, textTransform: 'uppercase' }}>{label}</span>
        {icon && <span style={{ color: 'var(--text-muted)', display: 'inline-flex' }}>{icon}</span>}
      </div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginBottom: 6 }}>
        <span className="ya-serif ya-tnum" style={{ fontSize: 26, fontWeight: 500, letterSpacing: '-0.015em', color: empty ? 'var(--text-muted)' : 'var(--text-primary)', lineHeight: 1.1 }}>
          {empty ? '—' : value}
        </span>
        {!empty && suffix && <span className="ya-serif" style={{ fontSize: 14, color: 'var(--text-muted)' }}>{suffix}</span>}
      </div>
      {trend && !empty ? (
        <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: 'var(--text-secondary)' }}>
          <span style={{ color: trendColor, display: 'inline-flex', alignItems: 'center', gap: 2 }}>
            <TrendIco />
            <span style={{ fontWeight: 500 }} className="ya-tnum">{trend.value}</span>
          </span>
          <span style={{ color: 'var(--text-muted)' }}>{trend.label}</span>
        </div>
      ) : (
        <div style={{ height: 11 }} />
      )}
    </div>
  );
}

function KpiCardShowcase() {
  const sectionTitle = { fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, margin: '0 0 12px' };
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
      <section>
        <h3 style={sectionTitle}>Default — KpiRow 4 colunas</h3>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
          <KpiCard label="Receita do mês" value="2 847 320" suffix="MTn" icon={Ico.TrendingUp(14)}
                   trend={{ value: '+18,4%', direction: 'up', semantic: 'positive', label: 'vs Abril' }} />
          <KpiCard label="Drivers activos" value="1 247" suffix="/ 1 380" icon={Ico.Users(14)}
                   trend={{ value: '+24', direction: 'up', semantic: 'positive', label: 'esta semana' }} />
          <KpiCard label="Corridas hoje" value="8 412" icon={Ico.Route(14)}
                   trend={{ value: '−3,2%', direction: 'down', semantic: 'negative', label: 'vs ontem' }} />
          <KpiCard label="Cancelamentos" value="4,1" suffix="%" icon={Ico.Car(14)}
                   trend={{ value: '−0,8pp', direction: 'down', semantic: 'positive', label: 'este mês' }} />
        </div>
      </section>

      <section>
        <h3 style={sectionTitle}>Variantes & estados</h3>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
          <KpiCard label="Highlighted" value="98,2" suffix="%" variant="highlighted"
                   trend={{ value: '+1,1pp', direction: 'up', semantic: 'positive', label: 'SLA esta semana' }} />
          <KpiCard label="Hover (clicável)" value="312" hover onTap
                   trend={{ value: '+12', direction: 'up', semantic: 'positive', label: 'novos partners' }} />
          <KpiCard label="Flat / estável" value="4,82" suffix="★"
                   trend={{ value: '0,0%', direction: 'flat', semantic: 'neutral', label: 'rating médio' }} />
          <KpiCard label="Down — bom" value="187" suffix="MTn"
                   trend={{ value: '−12%', direction: 'down', semantic: 'positive', label: 'reembolsos' }} />
        </div>
      </section>

      <section>
        <h3 style={sectionTitle}>Loading & empty</h3>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
          <KpiCard loading />
          <KpiCard loading />
          <KpiCard label="Sem dados" value="" empty />
          <KpiCard label="Em curso agora" value="247" icon={Ico.Route(14)}
                   trend={{ value: '', direction: 'flat', semantic: 'neutral', label: 'a decorrer' }} />
        </div>
      </section>
    </div>
  );
}

window.KpiCardShowcase = KpiCardShowcase;
window.KpiCard = KpiCard;
