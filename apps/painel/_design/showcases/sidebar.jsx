/* global React, YA */
const { Ico } = window.YA;
const { useState } = React;

function NavItem({ icon, label, active, hovered, focused, disabled, badge, collapsed, state }) {
  // Compute background/color
  let bg = 'transparent', color = 'var(--text-secondary)', weight = 400, ring = 'none';
  if (active) { bg = 'var(--brand-subtle)'; color = 'var(--brand)'; weight = 500; }
  if (active && hovered) { bg = 'var(--brand-subtle-hover)'; }
  if (!active && hovered) { bg = 'var(--bg-subtle)'; color = 'var(--text-primary)'; }
  if (focused) { bg = active ? 'var(--brand-subtle)' : 'var(--bg-subtle)'; ring = 'var(--shadow-focus)'; if (!active) color = 'var(--text-primary)'; }
  if (disabled) { color = 'var(--text-disabled)'; bg = 'transparent'; }

  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 9,
      padding: collapsed ? '6px' : '6px 8px',
      justifyContent: collapsed ? 'center' : 'flex-start',
      borderRadius: 5, marginBottom: 1,
      background: bg, color, fontWeight: weight,
      fontSize: 12.5, lineHeight: 1.2,
      cursor: disabled ? 'not-allowed' : 'pointer',
      opacity: disabled ? 0.5 : 1,
      boxShadow: ring,
      transition: 'background 120ms, color 120ms',
      position: 'relative',
    }}>
      <span style={{ display: 'inline-flex', flexShrink: 0, opacity: active ? 1 : (hovered || focused ? 1 : 0.85) }}>{icon}</span>
      {!collapsed && (
        <>
          <span style={{ flex: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{label}</span>
          {badge != null && (
            <span className="ya-tnum" style={{
              fontSize: 10, padding: '1px 6px', borderRadius: 9999,
              background: active ? 'var(--brand)' : 'var(--brand-subtle)',
              color: active ? 'var(--text-inverse)' : 'var(--brand)',
              fontWeight: 500, lineHeight: '14px',
            }}>{badge > 99 ? '99+' : badge}</span>
          )}
        </>
      )}
      {state && (
        <span style={{
          position: 'absolute', right: -4, top: -4,
          fontSize: 9, padding: '1px 5px', borderRadius: 3,
          background: 'var(--info-subtle)', color: 'var(--info)',
          fontWeight: 500, letterSpacing: '0.04em', textTransform: 'uppercase',
        }}>{state}</span>
      )}
    </div>
  );
}

function SidebarFrame({ role = 'ADMIN', collapsed = false, children, height = 640 }) {
  return (
    <div style={{
      width: collapsed ? 56 : 240, height,
      background: 'var(--bg-surface)',
      borderRight: '1px solid var(--border-subtle)',
      borderRadius: 8,
      display: 'flex', flexDirection: 'column',
      overflow: 'hidden', flexShrink: 0,
    }}>
      <div style={{ padding: collapsed ? '18px 8px 16px' : '18px 10px 16px' }}>
        <div className="ya-serif" style={{
          fontSize: 24, lineHeight: 1, fontWeight: 500,
          letterSpacing: '-0.02em', color: 'var(--text-primary)',
          padding: collapsed ? '0' : '0 8px', textAlign: collapsed ? 'center' : 'left',
        }}>YA</div>
        {!collapsed && (
          <div style={{
            fontSize: 10, letterSpacing: '0.14em', textTransform: 'uppercase',
            color: 'var(--text-muted)', fontWeight: 500,
            padding: '6px 8px 0', marginBottom: 22,
          }}>PAINEL · {role}</div>
        )}
      </div>
      <div style={{ flex: 1, overflow: 'auto', padding: collapsed ? '0 8px' : '0 10px' }}>
        {children}
      </div>
      {/* Footer */}
      <div style={{ padding: collapsed ? '12px 8px' : '12px 10px', borderTop: '1px solid var(--border-subtle)' }}>
        {collapsed ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6, alignItems: 'center' }}>
            <div style={{ width: 28, height: 28, borderRadius: 9999, background: 'oklch(0.32 0.05 30)', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 11, fontWeight: 500 }}>JT</div>
          </div>
        ) : (
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 4px' }}>
            <div style={{ width: 28, height: 28, borderRadius: 9999, background: 'oklch(0.32 0.05 30)', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 11, fontWeight: 500, flexShrink: 0 }}>JT</div>
            <div style={{ minWidth: 0, flex: 1 }}>
              <div style={{ fontSize: 12, color: 'var(--text-primary)', fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>João Tembe</div>
              <div style={{ fontSize: 10.5, color: 'var(--text-muted)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>j.tembe@ya.mz</div>
            </div>
            <button style={{ width: 24, height: 24, border: 'none', background: 'transparent', color: 'var(--text-muted)', cursor: 'pointer', borderRadius: 4, display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }} aria-label="Tema">{Ico.Sun()}</button>
          </div>
        )}
      </div>
    </div>
  );
}

function Group({ title, collapsed, children }) {
  return (
    <div>
      {!collapsed && (
        <div style={{ fontSize: 10.5, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, padding: '14px 8px 5px' }}>{title}</div>
      )}
      {collapsed && <div style={{ height: 12 }} />}
      {children}
    </div>
  );
}

function SidebarShowcase() {
  const sectionTitle = { fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, margin: '0 0 12px' };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 28 }}>
      <section>
        <h3 style={sectionTitle}>Admin — todos os estados de NavItem</h3>
        <div style={{ display: 'flex', gap: 16, alignItems: 'flex-start' }}>
          <SidebarFrame role="ADMIN" height={680}>
            <Group title="Geral">
              <NavItem icon={Ico.Dashboard()} label="Dashboard" active />
            </Group>
            <Group title="Gestão">
              <NavItem icon={Ico.FileText()} label="Documentos" badge={12} />
              <NavItem icon={Ico.Building()} label="Partners" hovered />
              <NavItem icon={Ico.Badge()} label="Frotas" />
              <NavItem icon={Ico.User()} label="Drivers" badge={247} />
              <NavItem icon={Ico.Car()} label="Veículos" focused />
              <NavItem icon={Ico.Users()} label="Utilizadores" />
            </Group>
            <Group title="Operações">
              <NavItem icon={Ico.Route()} label="Corridas" badge={8} />
              <NavItem icon={Ico.Map()} label="Mapa live" />
            </Group>
            <Group title="Financeiro">
              <NavItem icon={Ico.Trending()} label="Finanças" />
              <NavItem icon={Ico.Percent()} label="Comissões" />
              <NavItem icon={Ico.History()} label="Histórico" disabled />
              <NavItem icon={Ico.Tag()} label="Pricing" />
            </Group>
            <Group title="Sistema">
              <NavItem icon={Ico.Bell()} label="Notificações" badge={3} />
              <NavItem icon={Ico.Bar()} label="Relatórios" />
              <NavItem icon={Ico.Settings()} label="Definições" />
            </Group>
          </SidebarFrame>

          {/* Annotations */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14, paddingTop: 70, fontSize: 12, color: 'var(--text-secondary)', flex: 1, maxWidth: 380 }}>
            <Annot dot="var(--brand)" label="Active" desc="bg brand.subtle, color brand, weight 500" />
            <Annot dot="var(--text-primary)" label="Hover" desc="bg bg.subtle, color text.primary" />
            <Annot dot="var(--brand-border)" label="Focus (teclado)" desc="ring shadow.focus 3px brand 22%" />
            <Annot dot="var(--text-disabled)" label="Disabled" desc="opacity 0.5, cursor not-allowed, sem hover" />
            <Annot dot="var(--text-secondary)" label="Default" desc="transparent, color text.secondary" />
            <Annot dot="var(--brand)" label="Badge" desc="contador esquerda; bg brand.subtle, color brand. > 99 → 99+" />
          </div>
        </div>
      </section>

      <section>
        <h3 style={sectionTitle}>Variantes por role + collapsed</h3>
        <div style={{ display: 'flex', gap: 16, alignItems: 'flex-start', flexWrap: 'wrap' }}>
          {/* Partner */}
          <SidebarFrame role="PARTNER" height={520}>
            <Group title="Geral">
              <NavItem icon={Ico.Dashboard()} label="Dashboard" />
            </Group>
            <Group title="Operação">
              <NavItem icon={Ico.Badge()} label="Frota" active />
              <NavItem icon={Ico.User()} label="Drivers" />
              <NavItem icon={Ico.Car()} label="Veículos" />
              <NavItem icon={Ico.Route()} label="Corridas" />
            </Group>
            <Group title="Financeiro">
              <NavItem icon={Ico.Trending()} label="Ganhos" />
              <NavItem icon={Ico.Bar()} label="Performance" />
              <NavItem icon={Ico.Tag()} label="Incentivos" />
            </Group>
          </SidebarFrame>

          {/* Support */}
          <SidebarFrame role="SUPPORT" height={520}>
            <Group title="Geral">
              <NavItem icon={Ico.Dashboard()} label="Dashboard" />
            </Group>
            <Group title="Atendimento">
              <NavItem icon={Ico.Bell()} label="Fila" badge={12} active />
              <NavItem icon={Ico.FileText()} label="Tickets" badge={47} />
              <NavItem icon={Ico.Users()} label="Chat ao vivo" />
            </Group>
            <Group title="Análise">
              <NavItem icon={Ico.Bar()} label="Performance" />
            </Group>
          </SidebarFrame>

          {/* Collapsed */}
          <SidebarFrame role="ADMIN" height={520} collapsed>
            <Group collapsed>
              <NavItem icon={Ico.Dashboard()} label="Dashboard" active collapsed />
            </Group>
            <Group collapsed>
              <NavItem icon={Ico.FileText()} label="Documentos" collapsed />
              <NavItem icon={Ico.Building()} label="Partners" collapsed />
              <NavItem icon={Ico.User()} label="Drivers" collapsed />
              <NavItem icon={Ico.Car()} label="Veículos" collapsed />
            </Group>
            <Group collapsed>
              <NavItem icon={Ico.Route()} label="Corridas" collapsed />
              <NavItem icon={Ico.Map()} label="Mapa" collapsed />
            </Group>
            <Group collapsed>
              <NavItem icon={Ico.Trending()} label="Finanças" collapsed />
              <NavItem icon={Ico.Settings()} label="Definições" collapsed />
            </Group>
          </SidebarFrame>
        </div>
      </section>
    </div>
  );
}

function Annot({ dot, label, desc }) {
  return (
    <div style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
      <span style={{ width: 8, height: 8, borderRadius: 9999, background: dot, marginTop: 6, flexShrink: 0 }} />
      <div>
        <div style={{ color: 'var(--text-primary)', fontWeight: 500, fontSize: 12 }}>{label}</div>
        <div style={{ color: 'var(--text-muted)', fontSize: 11.5, marginTop: 2 }}>{desc}</div>
      </div>
    </div>
  );
}

window.SidebarShowcase = SidebarShowcase;
window.SidebarFrame = SidebarFrame;
window.NavItem = NavItem;
window.SidebarGroup = Group;
