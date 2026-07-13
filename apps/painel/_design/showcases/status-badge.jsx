/* global React, YA */
const { StatusBadge, Ico } = window.YA;
const { useState } = React;

// ============== StatusBadge Showcase ==============
function StatusBadgeShowcase() {
  const variants = [
    { v: 'success', label: 'Activo' },
    { v: 'warning', label: 'Pendente' },
    { v: 'danger', label: 'Suspenso' },
    { v: 'info', label: 'Em atendimento' },
    { v: 'neutral', label: 'Fechado' },
    { v: 'brand', label: 'Premium' },
  ];

  const cellStyle = { padding: '14px 16px', borderBottom: '1px solid var(--border-subtle)' };
  const headStyle = { ...cellStyle, fontSize: 11, fontWeight: 500, color: 'var(--text-secondary)', letterSpacing: '0.02em', textTransform: 'uppercase', background: 'var(--bg-surface)' };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
      {/* Variants table */}
      <section>
        <h3 style={{ fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, margin: '0 0 12px' }}>Variantes semânticas</h3>
        <div style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)', borderRadius: 8, overflow: 'hidden' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', alignItems: 'center' }}>
            <div style={headStyle}>Token</div>
            <div style={headStyle}>Default (md, dot)</div>
            <div style={headStyle}>Com ícone</div>
            <div style={headStyle}>Small (sm)</div>
            {variants.map((v, i) => {
              const icon = v.v === 'success' ? Ico.Check() : v.v === 'warning' ? Ico.Clock() : v.v === 'danger' ? Ico.Alert() : null;
              const isLast = i === variants.length - 1;
              const cs = isLast ? { ...cellStyle, borderBottom: 'none' } : cellStyle;
              return (
                <React.Fragment key={v.v}>
                  <div style={cs}><span className="ya-mono" style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{v.v}</span></div>
                  <div style={cs}><StatusBadge variant={v.v} label={v.label} /></div>
                  <div style={cs}>{icon ? <StatusBadge variant={v.v} label={v.label} icon={icon} /> : <span style={{ color: 'var(--text-muted)', fontSize: 12 }}>—</span>}</div>
                  <div style={cs}><StatusBadge variant={v.v} label={v.label} size="sm" /></div>
                </React.Fragment>
              );
            })}
          </div>
        </div>
      </section>

      {/* Domain examples */}
      <section>
        <h3 style={{ fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, margin: '0 0 12px' }}>Mapeamento canónico de domínio</h3>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 0, background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)', borderRadius: 8, overflow: 'hidden' }}>
          {[
            ['Driver', 'success', 'Activo · online'],
            ['Driver', 'neutral', 'Activo · offline'],
            ['Driver', 'warning', 'Pendente'],
            ['Driver', 'danger', 'Suspenso'],
            ['Vehicle', 'success', 'Disponível'],
            ['Vehicle', 'warning', 'Em corrida'],
            ['Vehicle', 'neutral', 'Em manutenção'],
            ['Trip', 'info', 'Aceite'],
            ['Trip', 'warning', 'A decorrer'],
            ['Trip', 'success', 'Completa'],
            ['Trip', 'danger', 'Cancelada'],
            ['Doc', 'success', 'OK'],
            ['Doc', 'warning', 'A expirar'],
            ['Doc', 'danger', 'Expirado'],
            ['Doc', 'neutral', 'Em falta'],
            ['Ticket', 'danger', 'Urgente'],
          ].map(([entity, v, label], i, arr) => {
            const isLastRow = i >= arr.length - 2;
            const isRightCol = i % 2 === 1;
            return (
              <div key={i} style={{
                padding: '10px 16px',
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                borderBottom: isLastRow ? 'none' : '1px solid var(--border-subtle)',
                borderRight: isRightCol ? 'none' : '1px solid var(--border-subtle)',
              }}>
                <span className="ya-mono" style={{ fontSize: 11, color: 'var(--text-muted)' }}>{entity}</span>
                <StatusBadge variant={v} label={label} />
              </div>
            );
          })}
        </div>
      </section>
    </div>
  );
}

window.StatusBadgeShowcase = StatusBadgeShowcase;
