/* global React, YA */
const { Ico } = window.YA;
const { useState } = React;

// ============== Button ==============
function Button({ variant = 'secondary', size = 'md', children, icon, loading = false, disabled = false, state = 'default' }) {
  const sizes = {
    sm: { h: 28, px: 12, gap: 6, fs: 12 },
    md: { h: 36, px: 16, gap: 8, fs: 13 },
    lg: { h: 40, px: 20, gap: 8, fs: 14 },
  };
  const s = sizes[size];
  const variants = {
    primary:    { bg: 'var(--brand)', color: '#FFFFFF', border: 'none' },
    secondary:  { bg: 'transparent', color: 'var(--text-primary)', border: '1px solid var(--border-default)' },
    ghost:      { bg: 'transparent', color: 'var(--text-secondary)', border: 'none' },
    destructive:{ bg: 'var(--danger)', color: '#FFFFFF', border: 'none' },
    link:       { bg: 'transparent', color: 'var(--brand)', border: 'none' },
  };
  let v = { ...variants[variant] };
  let ring = 'none';
  if (state === 'hover') {
    if (variant === 'primary') v.bg = 'var(--brand-hover)';
    else if (variant === 'secondary' || variant === 'ghost') { v.bg = 'var(--bg-subtle)'; v.color = 'var(--text-primary)'; }
    else if (variant === 'destructive') v.bg = '#B91C1C';
    else if (variant === 'link') v.color = 'var(--brand-hover)';
  }
  if (state === 'active') {
    if (variant === 'primary') v.bg = 'var(--brand-active)';
    else if (variant === 'secondary' || variant === 'ghost') v.bg = 'var(--bg-elevated)';
  }
  if (state === 'focus') ring = variant === 'destructive' ? 'var(--shadow-focus-danger)' : 'var(--shadow-focus)';
  if (disabled) { v.bg = 'var(--bg-subtle)'; v.color = 'var(--text-disabled)'; v.border = '1px solid var(--border-subtle)'; }

  const showIcon = icon && !loading;
  const showSpinner = loading;

  return (
    <button disabled={disabled} style={{
      height: s.h, padding: `0 ${s.px}px`,
      borderRadius: 6, border: v.border, background: v.bg, color: v.color,
      fontSize: s.fs, fontWeight: 500, fontFamily: 'inherit',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: s.gap,
      cursor: disabled ? 'not-allowed' : 'pointer',
      boxShadow: ring,
      textDecoration: variant === 'link' && state === 'hover' ? 'underline' : 'none',
      transition: 'all 120ms',
    }}>
      {showSpinner && <Spinner size={14} />}
      {showIcon && <span style={{ display: 'inline-flex' }}>{icon}</span>}
      <span>{children}</span>
    </button>
  );
}

function Spinner({ size = 14 }) {
  return (
    <span style={{
      width: size, height: size, borderRadius: 9999,
      border: '2px solid currentColor', borderTopColor: 'transparent',
      display: 'inline-block', animation: 'ya-spin 0.7s linear infinite',
    }}>
      <style>{`@keyframes ya-spin { to { transform: rotate(360deg); } }`}</style>
    </span>
  );
}

// ============== Input ==============
function Input({ value = '', placeholder, label, hint, error, size = 'md', state = 'default', icon, type = 'text', disabled = false }) {
  const h = size === 'lg' ? 36 : 32;
  let border = '1px solid var(--border-default)';
  let ring = 'none';
  let bg = 'var(--bg-surface)';
  if (state === 'hover') border = '1px solid var(--border-strong)';
  if (state === 'focus') { border = '1px solid var(--brand-border)'; ring = 'var(--shadow-focus)'; }
  if (error) { border = '1px solid var(--danger)'; ring = 'var(--shadow-focus-danger)'; }
  if (disabled) { bg = 'var(--bg-subtle)'; border = '1px solid var(--border-subtle)'; }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, minWidth: 0 }}>
      {label && <label style={{ fontSize: 12, color: 'var(--text-secondary)', fontWeight: 500 }}>{label}</label>}
      <div style={{ position: 'relative' }}>
        {icon && (
          <span style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', display: 'inline-flex', pointerEvents: 'none' }}>{icon}</span>
        )}
        <input
          type={type}
          defaultValue={value}
          placeholder={placeholder}
          disabled={disabled}
          style={{
            width: '100%', height: h,
            padding: icon ? '0 12px 0 32px' : '0 12px',
            borderRadius: 6, border,
            background: bg,
            color: disabled ? 'var(--text-disabled)' : 'var(--text-primary)',
            fontSize: 13, fontFamily: 'inherit', outline: 'none',
            boxShadow: ring,
            cursor: disabled ? 'not-allowed' : 'text',
            transition: 'all 120ms',
          }}
        />
      </div>
      {error ? (
        <div style={{ fontSize: 12, color: 'var(--danger)', display: 'flex', alignItems: 'center', gap: 4, marginTop: 2 }}>
          <span style={{ display: 'inline-flex' }}>{Ico.Alert(12)}</span>{error}
        </div>
      ) : hint ? (
        <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 2 }}>{hint}</div>
      ) : null}
    </div>
  );
}

// ============== Avatar ==============
function Avatar({ initial = 'JT', size = 32, hue = 30, hasPhoto = false, border = false }) {
  const fontSize = size <= 24 ? 10 : size <= 32 ? 12 : size <= 44 ? 15 : 20;
  return (
    <div style={{
      width: size, height: size, borderRadius: 9999,
      background: hasPhoto
        ? `oklch(0.45 0.08 ${hue})`
        : `oklch(0.32 0.05 ${hue})`,
      backgroundImage: hasPhoto
        ? `linear-gradient(135deg, oklch(0.55 0.10 ${hue}), oklch(0.35 0.06 ${hue + 30}))`
        : 'none',
      color: 'var(--text-primary)',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      fontSize, fontWeight: 500, letterSpacing: '0.01em',
      border: border ? '1.5px solid var(--border-subtle)' : 'none',
      flexShrink: 0,
    }}>{!hasPhoto && initial}</div>
  );
}

// ============== Tabs ==============
function Tabs({ items, activeIdx = 0, focused = -1 }) {
  return (
    <div style={{ borderBottom: '1px solid var(--border-subtle)', display: 'flex', gap: 0 }}>
      {items.map((it, i) => {
        const active = i === activeIdx;
        const isFocus = i === focused;
        return (
          <button key={i} style={{
            padding: '8px 16px', height: 36,
            background: 'transparent', border: 'none',
            borderBottom: '2px solid ' + (active ? 'var(--brand)' : 'transparent'),
            color: active ? 'var(--brand)' : 'var(--text-secondary)',
            fontSize: 13, fontWeight: 500, cursor: 'pointer',
            display: 'inline-flex', alignItems: 'center', gap: 6,
            marginBottom: -1,
            boxShadow: isFocus ? 'var(--shadow-focus)' : 'none',
            borderRadius: isFocus ? 4 : 0,
          }}>
            <span>{it.label}</span>
            {it.count != null && <span className="ya-tnum" style={{ color: 'var(--text-muted)', fontSize: 12 }}>({it.count})</span>}
          </button>
        );
      })}
    </div>
  );
}

// ============== Tooltip (static preview) ==============
function TooltipPreview({ text = 'Tooltip de exemplo', target }) {
  return (
    <div style={{ position: 'relative', display: 'inline-flex', flexDirection: 'column', alignItems: 'center', gap: 8, padding: '36px 0 0' }}>
      <div style={{
        position: 'absolute', top: 0, left: '50%', transform: 'translateX(-50%)',
        background: 'var(--text-primary)', color: 'var(--text-inverse)',
        fontSize: 12, padding: '6px 10px', borderRadius: 4, maxWidth: 240,
        whiteSpace: 'nowrap', fontWeight: 400,
      }}>{text}</div>
      {target}
    </div>
  );
}

// ============== Dropdown / Select ==============
function DropdownPreview({ open = true, label = 'Selecionar partner', selected = 'Maputo Executive' }) {
  const items = [
    { label: 'Maputo Executive', sel: true },
    { label: 'Beira Mobility' },
    { label: 'Nampula Trans' },
    { label: 'Pemba Rides' },
    { label: 'Tete Express' },
  ];
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4, width: 240 }}>
      <button style={{
        height: 32, padding: '0 12px', display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        borderRadius: 6, border: '1px solid var(--border-default)', background: 'var(--bg-surface)',
        color: 'var(--text-primary)', fontSize: 13, cursor: 'pointer', fontFamily: 'inherit',
        boxShadow: open ? 'var(--shadow-focus)' : 'none',
        borderColor: open ? 'var(--brand-border)' : 'var(--border-default)',
      }}>
        <span>{selected}</span>
        <span style={{ color: 'var(--text-muted)', display: 'inline-flex' }}>{Ico.ChevronDown(14)}</span>
      </button>
      {open && (
        <div style={{
          background: 'var(--bg-elevated)', border: '1px solid var(--border-subtle)',
          borderRadius: 6, padding: 4, boxShadow: 'var(--shadow-md)',
        }}>
          {items.map((it, i) => (
            <div key={i} style={{
              padding: '8px 10px', borderRadius: 4, fontSize: 13,
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              background: it.sel ? 'var(--brand-subtle)' : 'transparent',
              color: it.sel ? 'var(--brand)' : 'var(--text-primary)',
              cursor: 'pointer',
            }}>
              <span>{it.label}</span>
              {it.sel && <span style={{ display: 'inline-flex' }}>{Ico.Check(12)}</span>}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// ============== Toast ==============
function Toast({ variant = 'success', title, description, dismissable = true }) {
  const icons = {
    success: Ico.Check(16),
    info: Ico.Clock(16),
    warning: Ico.Alert(16),
    danger: Ico.Alert(16),
  };
  return (
    <div style={{
      background: 'var(--bg-elevated)',
      border: '1px solid var(--border-subtle)',
      borderLeft: `3px solid var(--${variant})`,
      borderRadius: 6, padding: '12px 16px',
      minWidth: 280, maxWidth: 400,
      boxShadow: 'var(--shadow-md)',
      display: 'flex', alignItems: 'flex-start', gap: 10,
    }}>
      <span style={{ color: `var(--${variant})`, display: 'inline-flex', marginTop: 1, flexShrink: 0 }}>{icons[variant]}</span>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)' }}>{title}</div>
        {description && <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 2 }}>{description}</div>}
      </div>
      {dismissable && (
        <button style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer', display: 'inline-flex', flexShrink: 0 }}>{Ico.X(14)}</button>
      )}
    </div>
  );
}

// ============== Showcase ==============
function AuxiliariesShowcase() {
  const sectionTitle = { fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, margin: '0 0 14px' };
  const subLabel = { fontSize: 11, color: 'var(--text-muted)', fontWeight: 400, marginBottom: 8, letterSpacing: '0.02em' };
  const grid = { display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 16, alignItems: 'flex-end' };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 32 }}>
      {/* BUTTONS */}
      <section>
        <h3 style={sectionTitle}>Button — variantes × estados</h3>
        <div style={{ display: 'grid', gridTemplateColumns: '90px repeat(5, 1fr)', gap: 12, alignItems: 'center' }}>
          <div />
          {['default', 'hover', 'active', 'focus', 'disabled'].map(st => (
            <div key={st} style={subLabel}>{st}</div>
          ))}
          {[
            ['primary', 'Aprovar', Ico.Check(14)],
            ['secondary', 'Exportar', Ico.Up(14)],
            ['ghost', 'Mais opções', null],
            ['destructive', 'Suspender', null],
            ['link', 'Ver detalhe', null],
          ].map(([variant, label, icon]) => (
            <React.Fragment key={variant}>
              <div style={{ fontSize: 11, color: 'var(--text-secondary)', fontWeight: 500, fontFamily: 'JetBrains Mono, monospace' }}>{variant}</div>
              {['default', 'hover', 'active', 'focus', 'disabled'].map(st => (
                <div key={st}>
                  <Button variant={variant} icon={icon} state={st === 'disabled' ? 'default' : st} disabled={st === 'disabled'}>{label}</Button>
                </div>
              ))}
            </React.Fragment>
          ))}
        </div>
        {/* Sizes */}
        <div style={{ marginTop: 24 }}>
          <div style={subLabel}>Sizes (sm 28 · md 36 · lg 40) + loading</div>
          <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap' }}>
            <Button variant="primary" size="sm">Pequeno</Button>
            <Button variant="primary" size="md">Médio (default)</Button>
            <Button variant="primary" size="lg">Largo</Button>
            <Button variant="primary" loading>A guardar...</Button>
            <Button variant="secondary" loading>A processar</Button>
          </div>
        </div>
      </section>

      {/* INPUTS */}
      <section>
        <h3 style={sectionTitle}>Input — estados</h3>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 }}>
          <Input label="Default" placeholder="A. Macuvele" />
          <Input label="Hover" placeholder="A. Macuvele" state="hover" />
          <Input label="Focus" placeholder="A. Macuvele" state="focus" value="A. Macuvele" />
          <Input label="Com ícone (search)" placeholder="Pesquisar..." icon={Ico.Search()} />
          <Input label="Com hint" placeholder="+258 84 123 4567" hint="Formato: +258 8X XXX XXXX" />
          <Input label="Disabled" placeholder="Não editável" value="400 123 456" disabled />
          <Input label="Erro de validação" placeholder="NUIT" value="40012" error="NUIT incompleto (precisa de 9 dígitos)" />
          <Input label="Email" type="email" placeholder="nome@empresa.mz" />
          <Input label="Tamanho lg (search global)" placeholder="Pesquisar... (⌘K)" size="lg" icon={Ico.Search()} />
        </div>
      </section>

      {/* AVATAR */}
      <section>
        <h3 style={sectionTitle}>Avatar — tamanhos & variantes</h3>
        <div style={{ display: 'flex', gap: 28, alignItems: 'flex-end', flexWrap: 'wrap' }}>
          {[24, 32, 44, 64].map(sz => (
            <div key={sz} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
              <Avatar initial="JT" size={sz} hue={30} />
              <span style={{ fontSize: 11, color: 'var(--text-muted)' }} className="ya-mono">{sz}px</span>
            </div>
          ))}
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
            <Avatar initial="" size={44} hasPhoto hue={200} />
            <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>foto</span>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
            <Avatar initial="MM" size={44} hue={120} border />
            <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>com border</span>
          </div>
          <div style={{ display: 'flex', gap: 4, marginLeft: 16 }}>
            {[{i:'AM',h:30},{i:'BS',h:120},{i:'CM',h:280},{i:'DT',h:200},{i:'EN',h:60}].map((p,i) => (
              <div key={i} style={{ marginLeft: i ? -8 : 0 }}><Avatar initial={p.i} size={32} hue={p.h} border /></div>
            ))}
          </div>
        </div>
      </section>

      {/* TABS */}
      <section>
        <h3 style={sectionTitle}>Tabs — under-line style</h3>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: 24 }}>
          <div>
            <div style={subLabel}>Default</div>
            <Tabs items={[
              { label: 'Geral' },
              { label: 'Drivers', count: 24 },
              { label: 'Veículos', count: 18 },
              { label: 'Documentos', count: 12 },
              { label: 'Histórico' },
            ]} activeIdx={1} />
          </div>
          <div>
            <div style={subLabel}>Focus no índice 2</div>
            <Tabs items={[
              { label: 'Visão geral' },
              { label: 'Corridas', count: 247 },
              { label: 'Ganhos' },
              { label: 'Performance' },
            ]} activeIdx={0} focused={2} />
          </div>
        </div>
      </section>

      {/* TOOLTIP */}
      <section>
        <h3 style={sectionTitle}>Tooltip — bg inverso, sem arrow</h3>
        <div style={{ display: 'flex', gap: 48, alignItems: 'flex-start' }}>
          <TooltipPreview text="Aprovar partner" target={<Button variant="primary" icon={Ico.Check(14)}>Aprovar</Button>} />
          <TooltipPreview text="Exportar para CSV" target={<Button variant="secondary" icon={Ico.Up(14)}>Exportar</Button>} />
          <TooltipPreview text="ID copiado · TRP-2847A1" target={<span className="ya-mono" style={{ fontSize: 13, color: 'var(--text-secondary)', padding: '6px 8px', background: 'var(--bg-subtle)', borderRadius: 4 }}>TRP-2847A1</span>} />
        </div>
      </section>

      {/* DROPDOWN */}
      <section>
        <h3 style={sectionTitle}>Dropdown / Select</h3>
        <div style={{ display: 'flex', gap: 32, alignItems: 'flex-start' }}>
          <div>
            <div style={subLabel}>Closed</div>
            <DropdownPreview open={false} />
          </div>
          <div>
            <div style={subLabel}>Open (Maputo Executive selecionado)</div>
            <DropdownPreview open={true} />
          </div>
        </div>
      </section>

      {/* TOAST */}
      <section>
        <h3 style={sectionTitle}>Toast — top-right, border-left semantic</h3>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, width: 400 }}>
          <Toast variant="success" title="Partner aprovado." description="Maputo Executive já pode operar." />
          <Toast variant="info" title="A processar payout..." description="247 transacções em fila." />
          <Toast variant="warning" title="3 documentos a expirar." description="Renova nas próximas 48h." />
          <Toast variant="danger" title="Não foi possível guardar." description="Sem ligação ao servidor. Tenta novamente." />
        </div>
      </section>
    </div>
  );
}

window.AuxiliariesShowcase = AuxiliariesShowcase;
window.YA_Button = Button;
window.YA_Input = Input;
window.YA_Avatar = Avatar;
window.YA_Toast = Toast;
window.YA_Tabs = Tabs;
window.YA_Dropdown = DropdownPreview;
