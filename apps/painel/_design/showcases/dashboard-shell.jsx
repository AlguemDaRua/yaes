/* global React, YA */
const { Ico } = window.YA;

function DashboardShellShowcase() {
  const sectionTitle = { fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, margin: '0 0 12px' };

  // Inline mini sidebar for shell preview
  const MiniNav = ({ icon, label, active, badge }) => (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 9, padding: '6px 8px',
      borderRadius: 5, marginBottom: 1, fontSize: 12.5, lineHeight: 1.2,
      background: active ? 'var(--brand-subtle)' : 'transparent',
      color: active ? 'var(--brand)' : 'var(--text-secondary)',
      fontWeight: active ? 500 : 400,
    }}>
      <span style={{ display: 'inline-flex', flexShrink: 0 }}>{icon}</span>
      <span style={{ flex: 1 }}>{label}</span>
      {badge != null && (
        <span className="ya-tnum" style={{
          fontSize: 10, padding: '1px 6px', borderRadius: 9999,
          background: 'var(--brand-subtle)', color: 'var(--brand)',
          fontWeight: 500, lineHeight: '14px',
        }}>{badge}</span>
      )}
    </div>
  );

  const NavGroup = ({ title, children }) => (
    <div>
      <div style={{ fontSize: 10.5, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, padding: '14px 8px 5px' }}>{title}</div>
      {children}
    </div>
  );

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
      <section>
        <h3 style={sectionTitle}>Composição completa — sidebar + topbar + main + toast</h3>

        <div style={{
          height: 720, borderRadius: 12, overflow: 'hidden',
          border: '1px solid var(--border-subtle)',
          background: 'var(--bg-base)',
          display: 'flex',
          boxShadow: 'var(--shadow-md)',
          position: 'relative',
        }}>
          {/* Sidebar */}
          <aside style={{
            width: 240, background: 'var(--bg-surface)',
            borderRight: '1px solid var(--border-subtle)',
            display: 'flex', flexDirection: 'column',
            flexShrink: 0,
          }}>
            <div style={{ padding: '18px 10px 16px' }}>
              <div className="ya-serif" style={{ fontSize: 24, lineHeight: 1, fontWeight: 500, letterSpacing: '-0.02em', color: 'var(--text-primary)', padding: '0 8px' }}>YA</div>
              <div style={{ fontSize: 10, letterSpacing: '0.14em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, padding: '6px 8px 0' }}>PAINEL · ADMIN</div>
            </div>
            <div style={{ flex: 1, overflow: 'auto', padding: '0 10px' }}>
              <NavGroup title="Geral">
                <MiniNav icon={Ico.Dashboard()} label="Dashboard" active />
              </NavGroup>
              <NavGroup title="Gestão">
                <MiniNav icon={Ico.FileText()} label="Documentos" badge={12} />
                <MiniNav icon={Ico.Building()} label="Partners" />
                <MiniNav icon={Ico.User()} label="Drivers" badge={247} />
                <MiniNav icon={Ico.Car()} label="Veículos" />
              </NavGroup>
              <NavGroup title="Operações">
                <MiniNav icon={Ico.Route()} label="Corridas" badge={8} />
                <MiniNav icon={Ico.Map()} label="Mapa live" />
              </NavGroup>
              <NavGroup title="Financeiro">
                <MiniNav icon={Ico.Trending()} label="Finanças" />
                <MiniNav icon={Ico.Percent()} label="Comissões" />
              </NavGroup>
              <NavGroup title="Sistema">
                <MiniNav icon={Ico.Bell()} label="Notificações" badge={3} />
                <MiniNav icon={Ico.Settings()} label="Definições" />
              </NavGroup>
            </div>
            <div style={{ padding: '12px 10px', borderTop: '1px solid var(--border-subtle)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 4px' }}>
                <div style={{ width: 28, height: 28, borderRadius: 9999, background: 'oklch(0.32 0.05 30)', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 11, fontWeight: 500 }}>JT</div>
                <div style={{ minWidth: 0, flex: 1 }}>
                  <div style={{ fontSize: 12, color: 'var(--text-primary)', fontWeight: 500 }}>João Tembe</div>
                  <div style={{ fontSize: 10.5, color: 'var(--text-muted)' }}>j.tembe@ya.mz</div>
                </div>
                <button style={{ width: 24, height: 24, border: 'none', background: 'transparent', color: 'var(--text-muted)', cursor: 'pointer', borderRadius: 4, display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>{Ico.Sun()}</button>
              </div>
            </div>
          </aside>

          {/* Main column */}
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
            {/* Topbar */}
            <header style={{
              height: 56, padding: '0 24px',
              background: 'var(--bg-surface)',
              borderBottom: '1px solid var(--border-subtle)',
              display: 'flex', alignItems: 'center', gap: 12,
              flexShrink: 0,
            }}>
              <div style={{ position: 'relative', flex: 1, maxWidth: 320 }}>
                <span style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', display: 'inline-flex' }}>{Ico.Search()}</span>
                <input placeholder="Pesquisar... (⌘K)" style={{
                  width: '100%', height: 36, paddingLeft: 32, paddingRight: 12,
                  borderRadius: 6, border: '1px solid var(--border-default)',
                  background: 'var(--bg-base)', color: 'var(--text-primary)',
                  fontSize: 13, fontFamily: 'inherit', outline: 'none',
                }} />
              </div>
              <div style={{ flex: 1 }} />
              <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 9999, background: 'var(--warning-subtle)', color: 'var(--warning)', fontWeight: 500, letterSpacing: '0.04em' }}>DEV</span>
              <button style={{ width: 32, height: 32, border: 'none', borderRadius: 6, background: 'transparent', color: 'var(--text-secondary)', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>{Ico.Sun()}</button>
              <button style={{ width: 32, height: 32, border: 'none', borderRadius: 6, background: 'transparent', color: 'var(--text-secondary)', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
                {Ico.Bell()}
                <span style={{ position: 'absolute', top: 7, right: 8, width: 6, height: 6, borderRadius: 9999, background: 'var(--danger)' }} />
              </button>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, paddingLeft: 8, borderLeft: '1px solid var(--border-subtle)' }}>
                <div style={{ width: 28, height: 28, borderRadius: 9999, background: 'oklch(0.32 0.05 30)', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 11, fontWeight: 500 }}>JT</div>
              </div>
            </header>

            {/* Main */}
            <main style={{ flex: 1, overflow: 'auto', padding: 32, background: 'var(--bg-base)' }}>
              {/* PageHeader */}
              <div style={{ marginBottom: 24, display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 24 }}>
                <div>
                  <div style={{ fontSize: 13, color: 'var(--text-muted)', marginBottom: 4 }}>Dashboard</div>
                  <h1 className="ya-serif" style={{ fontSize: 24, fontWeight: 500, color: 'var(--text-primary)', margin: 0, letterSpacing: '-0.015em', lineHeight: 1.3 }}>Visão geral</h1>
                  <p style={{ fontSize: 13, color: 'var(--text-secondary)', margin: '4px 0 0' }}>Operações em tempo real · 3 de Maio de 2026</p>
                </div>
                <div style={{ display: 'flex', gap: 8 }}>
                  <button style={{
                    height: 36, padding: '0 16px', borderRadius: 6,
                    border: '1px solid var(--border-default)', background: 'transparent',
                    color: 'var(--text-primary)', fontSize: 13, fontWeight: 500, cursor: 'pointer',
                  }}>Exportar CSV</button>
                  <button style={{
                    height: 36, padding: '0 16px', borderRadius: 6,
                    border: 'none', background: 'var(--brand)',
                    color: '#FFFFFF', fontSize: 13, fontWeight: 500, cursor: 'pointer',
                  }}>Novo partner</button>
                </div>
              </div>

              {/* KPI row */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 24 }}>
                {window.KpiCard && [
                  { label: 'Receita do mês', value: '2 847 320', suffix: 'MTn', trend: { value: '+18,4%', direction: 'up', semantic: 'positive', label: 'vs Abril' }, icon: Ico.TrendingUp(14) },
                  { label: 'Drivers activos', value: '1 247', suffix: '/ 1 380', trend: { value: '+24', direction: 'up', semantic: 'positive', label: 'esta semana' }, icon: Ico.Users(14) },
                  { label: 'Corridas hoje', value: '8 412', trend: { value: '−3,2%', direction: 'down', semantic: 'negative', label: 'vs ontem' }, icon: Ico.Route(14) },
                  { label: 'Cancelamentos', value: '4,1', suffix: '%', trend: { value: '−0,8pp', direction: 'down', semantic: 'positive', label: 'este mês' }, icon: Ico.Car(14) },
                ].map((p, i) => React.createElement(window.KpiCard, { key: i, ...p }))}
              </div>

              {/* DataTable */}
              {window.DataTable && React.createElement(window.DataTable)}
            </main>
          </div>

          {/* Toast */}
          <div style={{
            position: 'absolute', top: 76, right: 32,
            background: 'var(--bg-elevated)',
            border: '1px solid var(--border-subtle)',
            borderLeft: '3px solid var(--success)',
            borderRadius: 6, padding: '12px 16px', minWidth: 280, maxWidth: 360,
            boxShadow: 'var(--shadow-md)',
            display: 'flex', alignItems: 'flex-start', gap: 10,
          }}>
            <span style={{ color: 'var(--success)', display: 'inline-flex', marginTop: 1 }}>{Ico.Check(16)}</span>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)' }}>Partner aprovado.</div>
              <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 2 }}>Maputo Executive já pode operar.</div>
            </div>
            <button style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer', display: 'inline-flex' }}>{Ico.X(14)}</button>
          </div>
        </div>
      </section>

      <section>
        <h3 style={sectionTitle}>Loading state — auth a verificar</h3>
        <div style={{
          height: 280, borderRadius: 12, border: '1px solid var(--border-subtle)',
          background: 'var(--bg-base)',
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 16,
        }}>
          <div className="ya-serif" style={{ fontSize: 36, fontWeight: 500, letterSpacing: '-0.02em', color: 'var(--text-primary)' }}>YA</div>
          <div style={{ fontSize: 11, letterSpacing: '0.14em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500 }}>A verificar sessão...</div>
          <div style={{ width: 200, height: 2, background: 'var(--bg-subtle)', borderRadius: 9999, overflow: 'hidden', position: 'relative' }}>
            <div style={{
              position: 'absolute', height: '100%', width: '40%',
              background: 'var(--brand)', borderRadius: 9999,
              animation: 'ya-progress 1.5s ease-in-out infinite',
            }} />
          </div>
          <style>{`@keyframes ya-progress { 0% { left: -40%; } 100% { left: 100%; } }`}</style>
        </div>
      </section>
    </div>
  );
}

window.DashboardShellShowcase = DashboardShellShowcase;
