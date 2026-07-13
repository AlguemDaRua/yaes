/* global React, YA */
const { Ico, StatusBadge } = window.YA;
const { useState } = React;

// ============== FormDialog ==============
function FormDialog({ title, description, children, confirmLabel = 'Confirmar', cancelLabel = 'Cancelar', destructive = false, submitting = false, errorBanner = null, confirmDisabled = false }) {
  return (
    <div style={{ position: 'relative', height: 560, background: 'var(--bg-overlay)', borderRadius: 12, overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <div style={{
        width: 480, maxWidth: '90%', background: 'var(--bg-surface)',
        borderRadius: 12, boxShadow: 'var(--shadow-lg)',
        border: '1px solid var(--border-subtle)',
        display: 'flex', flexDirection: 'column', maxHeight: '85%',
      }}>
        <div style={{ padding: '24px 24px 16px', borderBottom: '1px solid var(--border-subtle)', position: 'relative' }}>
          <div style={{ fontSize: 17, fontWeight: 500, color: 'var(--text-primary)' }}>{title}</div>
          {description && <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginTop: 4 }}>{description}</div>}
          <button style={{ position: 'absolute', top: 16, right: 16, width: 28, height: 28, border: 'none', background: 'transparent', color: 'var(--text-muted)', cursor: 'pointer', borderRadius: 4, display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>{Ico.X(16)}</button>
        </div>
        {errorBanner && (
          <div style={{ margin: '16px 24px 0', padding: '10px 12px', borderRadius: 6, background: 'var(--danger-subtle)', color: 'var(--danger)', fontSize: 12, display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ display: 'inline-flex' }}>{Ico.Alert(14)}</span>{errorBanner}
          </div>
        )}
        <div style={{ padding: 24, overflow: 'auto', display: 'flex', flexDirection: 'column', gap: 16 }}>
          {children}
        </div>
        <div style={{ padding: '16px 24px', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
          <button style={{
            height: 36, padding: '0 16px', borderRadius: 6,
            border: '1px solid var(--border-default)', background: 'transparent',
            color: 'var(--text-primary)', fontSize: 13, fontWeight: 500, cursor: 'pointer',
          }}>{cancelLabel}</button>
          <button disabled={confirmDisabled} style={{
            height: 36, padding: '0 16px', borderRadius: 6,
            border: 'none',
            background: confirmDisabled ? 'var(--bg-subtle)' : (destructive ? 'var(--danger)' : 'var(--brand)'),
            color: confirmDisabled ? 'var(--text-disabled)' : '#FFFFFF',
            fontSize: 13, fontWeight: 500,
            cursor: confirmDisabled ? 'not-allowed' : 'pointer',
            display: 'inline-flex', alignItems: 'center', gap: 8,
          }}>
            {submitting && <span style={{ width: 14, height: 14, borderRadius: 9999, border: '2px solid currentColor', borderTopColor: 'transparent', display: 'inline-block', animation: 'ya-spin 0.7s linear infinite' }} />}
            {submitting ? 'A guardar...' : confirmLabel}
          </button>
        </div>
      </div>
      <style>{`@keyframes ya-spin { to { transform: rotate(360deg); } }`}</style>
    </div>
  );
}

function Field({ label, children, hint }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <label style={{ fontSize: 12, color: 'var(--text-secondary)', fontWeight: 500 }}>{label}</label>
      {children}
      {hint && <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>{hint}</div>}
    </div>
  );
}

function FInput({ value, placeholder, mono = false }) {
  return (
    <input defaultValue={value} placeholder={placeholder} style={{
      height: 32, padding: '0 12px', borderRadius: 6,
      border: '1px solid var(--border-default)', background: 'var(--bg-surface)',
      color: 'var(--text-primary)', fontSize: 13, outline: 'none',
      fontFamily: mono ? 'JetBrains Mono, monospace' : 'inherit',
    }} />
  );
}

function FormDialogShowcase() {
  const sectionTitle = { fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, margin: '0 0 14px' };
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
      <section>
        <h3 style={sectionTitle}>FormDialog — criação (default)</h3>
        <FormDialog title="Novo partner" description="Adiciona uma empresa parceira à plataforma.">
          <Field label="Nome da empresa"><FInput placeholder="Ex: Maputo Executive" /></Field>
          <Field label="NUIT" hint="9 dígitos sem espaços"><FInput value="400 123 456" mono /></Field>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <Field label="Email principal"><FInput placeholder="contacto@empresa.mz" /></Field>
            <Field label="Telefone"><FInput value="+258 84 123 4567" mono /></Field>
          </div>
          <Field label="Comissão" hint="Default 12%"><FInput value="12" /></Field>
        </FormDialog>
      </section>

      <section>
        <h3 style={sectionTitle}>FormDialog — submitting</h3>
        <FormDialog title="A criar partner..." submitting>
          <Field label="Nome"><FInput value="Maputo Executive" /></Field>
          <Field label="NUIT"><FInput value="400 123 456" mono /></Field>
        </FormDialog>
      </section>

      <section>
        <h3 style={sectionTitle}>FormDialog — error de servidor</h3>
        <FormDialog title="Editar comissão" errorBanner="Não foi possível guardar. Verifica a ligação e tenta novamente.">
          <Field label="Comissão actual"><FInput value="15" /></Field>
          <Field label="Motivo da alteração"><FInput placeholder="Ex: ajuste sazonal Q2" /></Field>
        </FormDialog>
      </section>

      <section>
        <h3 style={sectionTitle}>ConfirmDialog — destrutivo (suspender driver)</h3>
        <div style={{ position: 'relative', height: 480, background: 'var(--bg-overlay)', borderRadius: 12, overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ width: 400, background: 'var(--bg-surface)', borderRadius: 12, boxShadow: 'var(--shadow-lg)', border: '1px solid var(--border-subtle)' }}>
            <div style={{ padding: '24px 24px 16px', borderBottom: '1px solid var(--border-subtle)', display: 'flex', gap: 14, alignItems: 'flex-start' }}>
              <div style={{ width: 40, height: 40, borderRadius: 9999, background: 'var(--danger-subtle)', color: 'var(--danger)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>{Ico.Alert(20)}</div>
              <div>
                <div style={{ fontSize: 15, fontWeight: 500, color: 'var(--text-primary)' }}>Suspender driver João Mondlane?</div>
                <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginTop: 4, lineHeight: 1.5 }}>O driver será imediatamente desligado e deixará de receber corridas.</div>
              </div>
            </div>
            <div style={{ padding: 24 }}>
              <Field label="Motivo (visível no audit log)" hint="Mínimo 10 caracteres">
                <textarea defaultValue="Documento expirado e não" style={{
                  minHeight: 80, padding: '8px 12px', borderRadius: 6,
                  border: '1px solid var(--danger)', background: 'var(--bg-surface)',
                  color: 'var(--text-primary)', fontSize: 13, outline: 'none',
                  fontFamily: 'inherit', resize: 'vertical', boxShadow: 'var(--shadow-focus-danger)',
                }} />
              </Field>
            </div>
            <div style={{ padding: '16px 24px', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
              <button style={{ height: 36, padding: '0 16px', borderRadius: 6, border: '1px solid var(--border-default)', background: 'transparent', color: 'var(--text-primary)', fontSize: 13, fontWeight: 500, cursor: 'pointer', boxShadow: 'var(--shadow-focus)' }}>Cancelar</button>
              <button disabled style={{ height: 36, padding: '0 16px', borderRadius: 6, border: 'none', background: 'var(--bg-subtle)', color: 'var(--text-disabled)', fontSize: 13, fontWeight: 500, cursor: 'not-allowed' }}>Suspender</button>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}

// ============== FilterBar standalone ==============
function FilterBarShowcase() {
  const sectionTitle = { fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, margin: '0 0 14px' };
  const Chip = ({ label, count, active, hovered, semantic }) => {
    let bg = 'transparent', color = 'var(--text-secondary)', border = '1px solid var(--border-subtle)';
    if (hovered && !active) { bg = 'var(--bg-subtle)'; color = 'var(--text-primary)'; border = '1px solid var(--border-default)'; }
    if (active) { bg = `var(--${semantic || 'brand'}-subtle)`; color = `var(--${semantic || 'brand'})`; border = `1px solid var(--${semantic || 'brand'}-border)`; }
    return (
      <button style={{
        height: 28, padding: '0 12px', borderRadius: 9999, border, background: bg, color,
        fontSize: 12, fontWeight: active ? 500 : 400,
        display: 'inline-flex', alignItems: 'center', gap: 6, cursor: 'pointer',
      }}>{label}{count != null && <span className="ya-tnum" style={{ opacity: 0.7, fontSize: 11 }}>{count}</span>}</button>
    );
  };
  return (
    <section style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
      <h3 style={sectionTitle}>FilterChip — estados</h3>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
        <Chip label="Default" count={42} />
        <Chip label="Hover" count={42} hovered />
        <Chip label="Active" count={42} active />
        <Chip label="Active · success" count={198} active semantic="success" />
        <Chip label="Active · warning" count={24} active semantic="warning" />
        <Chip label="Active · danger" count={17} active semantic="danger" />
        <Chip label="Active · info" count={8} active semantic="info" />
      </div>

      <h3 style={sectionTitle}>FilterBar completa — search + filtros + chips</h3>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
          <div style={{ position: 'relative', flex: 1, maxWidth: 320 }}>
            <span style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', display: 'inline-flex' }}>{Ico.Search()}</span>
            <input defaultValue="mondlane" style={{ width: '100%', height: 32, paddingLeft: 32, paddingRight: 32, borderRadius: 6, border: '1px solid var(--border-default)', background: 'var(--bg-surface)', color: 'var(--text-primary)', fontSize: 13, fontFamily: 'inherit', outline: 'none' }} />
            <span style={{ position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', display: 'inline-flex', cursor: 'pointer' }}>{Ico.X(12)}</span>
          </div>
          <button style={{ height: 32, padding: '0 12px', borderRadius: 6, border: '1px solid var(--border-default)', background: 'transparent', color: 'var(--text-primary)', fontSize: 13, fontWeight: 500, cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 6 }}>
            Filtros <span style={{ background: 'var(--brand-subtle)', color: 'var(--brand)', padding: '1px 6px', borderRadius: 9999, fontSize: 10 }}>3</span>
          </button>
          <div style={{ flex: 1 }} />
          <button style={{ height: 32, padding: '0 12px', borderRadius: 6, border: '1px solid var(--border-default)', background: 'transparent', color: 'var(--text-primary)', fontSize: 13, fontWeight: 500, cursor: 'pointer' }}>Exportar</button>
          <button style={{ height: 32, padding: '0 12px', borderRadius: 6, border: 'none', background: 'var(--brand)', color: '#FFF', fontSize: 13, fontWeight: 500, cursor: 'pointer' }}>Novo driver</button>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          <Chip label="Todos" count={1247} active />
          <Chip label="Activos · online" count={847} semantic="success" />
          <Chip label="Activos · offline" count={328} />
          <Chip label="Pendentes" count={47} semantic="warning" />
          <Chip label="Suspensos" count={25} semantic="danger" />
        </div>
      </div>
    </section>
  );
}

// ============== RowContextMenu ==============
function RowContextMenuShowcase() {
  const sectionTitle = { fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, margin: '0 0 14px' };
  const Item = ({ icon, label, shortcut, destructive, hovered, disabled }) => {
    let bg = 'transparent', color = destructive ? 'var(--danger)' : 'var(--text-primary)';
    if (hovered) bg = destructive ? 'var(--danger-subtle)' : 'var(--bg-subtle)';
    if (disabled) { color = 'var(--text-disabled)'; bg = 'transparent'; }
    return (
      <div style={{
        padding: '6px 10px', borderRadius: 4, fontSize: 13,
        display: 'flex', alignItems: 'center', gap: 10, cursor: disabled ? 'not-allowed' : 'pointer',
        background: bg, color, opacity: disabled ? 0.4 : 1,
      }}>
        <span style={{ display: 'inline-flex', width: 14 }}>{icon}</span>
        <span style={{ flex: 1 }}>{label}</span>
        {shortcut && <span className="ya-mono" style={{ fontSize: 11, color: 'var(--text-muted)' }}>{shortcut}</span>}
      </div>
    );
  };
  const menuStyle = {
    background: 'var(--bg-elevated)', border: '1px solid var(--border-subtle)',
    borderRadius: 6, padding: 4, minWidth: 200, boxShadow: 'var(--shadow-md)',
  };
  return (
    <section>
      <h3 style={sectionTitle}>RowContextMenu — variantes por entidade</h3>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24 }}>
        <div>
          <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 8 }}>Partner row</div>
          <div style={menuStyle}>
            <Item icon={Ico.Search(14)} label="Ver detalhe" />
            <div style={{ borderTop: '1px solid var(--border-subtle)', margin: '4px 0' }} />
            <Item icon={Ico.Check(14)} label="Aprovar" hovered />
            <Item icon={Ico.Percent(14)} label="Editar comissão" shortcut="⌘E" />
            <div style={{ borderTop: '1px solid var(--border-subtle)', margin: '4px 0' }} />
            <Item icon={Ico.FileText(14)} label="Copiar NUIT" />
            <Item icon={Ico.FileText(14)} label="Copiar email" />
            <div style={{ borderTop: '1px solid var(--border-subtle)', margin: '4px 0' }} />
            <Item icon={Ico.Alert(14)} label="Suspender" destructive />
          </div>
        </div>
        <div>
          <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 8 }}>Driver row</div>
          <div style={menuStyle}>
            <Item icon={Ico.User(14)} label="Ver perfil" />
            <div style={{ borderTop: '1px solid var(--border-subtle)', margin: '4px 0' }} />
            <Item icon={Ico.Car(14)} label="Atribuir veículo" />
            <Item icon={Ico.Route(14)} label="Ver corridas" />
            <Item icon={Ico.FileText(14)} label="Copiar telefone" />
            <div style={{ borderTop: '1px solid var(--border-subtle)', margin: '4px 0' }} />
            <Item icon={Ico.Alert(14)} label="Suspender" destructive hovered />
          </div>
        </div>
        <div>
          <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 8 }}>Trip row · com disabled</div>
          <div style={menuStyle}>
            <Item icon={Ico.Search(14)} label="Ver detalhe" />
            <Item icon={Ico.FileText(14)} label="Copiar ID" shortcut="⌘C" />
            <div style={{ borderTop: '1px solid var(--border-subtle)', margin: '4px 0' }} />
            <Item icon={Ico.X(14)} label="Cancelar corrida" destructive disabled />
            <Item icon={Ico.Alert(14)} label="Emitir reembolso" destructive />
          </div>
        </div>
      </div>
    </section>
  );
}

// ============== PageHeader + Topbar ==============
function PageHeaderTopbarShowcase() {
  const sectionTitle = { fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, margin: '0 0 14px' };
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 28 }}>
      <section>
        <h3 style={sectionTitle}>Topbar — default + ícones direita</h3>
        <div style={{ height: 56, padding: '0 24px', background: 'var(--bg-surface)', borderRadius: 8, border: '1px solid var(--border-subtle)', display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{ position: 'relative', flex: 1, maxWidth: 320 }}>
            <span style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', display: 'inline-flex' }}>{Ico.Search()}</span>
            <input placeholder="Pesquisar... (⌘K)" style={{ width: '100%', height: 36, paddingLeft: 32, paddingRight: 12, borderRadius: 6, border: '1px solid var(--border-default)', background: 'var(--bg-base)', color: 'var(--text-primary)', fontSize: 13, fontFamily: 'inherit', outline: 'none' }} />
          </div>
          <div style={{ flex: 1 }} />
          <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 9999, background: 'var(--warning-subtle)', color: 'var(--warning)', fontWeight: 500, letterSpacing: '0.04em' }}>DEV</span>
          <button style={{ width: 32, height: 32, border: 'none', borderRadius: 6, background: 'transparent', color: 'var(--text-secondary)', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>{Ico.Sun()}</button>
          <button style={{ width: 32, height: 32, border: 'none', borderRadius: 6, background: 'transparent', color: 'var(--text-secondary)', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
            {Ico.Bell()}
            <span style={{ position: 'absolute', top: 7, right: 8, width: 6, height: 6, borderRadius: 9999, background: 'var(--danger)' }} />
          </button>
          <div style={{ width: 28, height: 28, borderRadius: 9999, background: 'oklch(0.32 0.05 30)', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 11, fontWeight: 500 }}>JT</div>
        </div>
      </section>

      <section>
        <h3 style={sectionTitle}>PageHeader — com breadcrumb, descrição e actions</h3>
        <div style={{ background: 'var(--bg-base)', padding: 24, borderRadius: 8, border: '1px solid var(--border-subtle)' }}>
          <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 24 }}>
            <div>
              <div style={{ fontSize: 13, color: 'var(--text-muted)', marginBottom: 4, display: 'flex', alignItems: 'center', gap: 6 }}>
                <span style={{ cursor: 'pointer' }}>Partners</span>
                <span style={{ opacity: 0.6 }}>›</span>
                <span style={{ color: 'var(--text-secondary)' }}>Maputo Executive</span>
              </div>
              <h1 className="ya-serif" style={{ fontSize: 24, fontWeight: 500, color: 'var(--text-primary)', margin: 0, letterSpacing: '-0.015em', lineHeight: 1.3 }}>Maputo Executive</h1>
              <p style={{ fontSize: 13, color: 'var(--text-secondary)', margin: '4px 0 0' }}>Empresa parceira · 47 drivers · 32 veículos · NUIT 400 123 456</p>
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <button style={{ height: 36, padding: '0 16px', borderRadius: 6, border: '1px solid var(--border-default)', background: 'transparent', color: 'var(--text-primary)', fontSize: 13, fontWeight: 500, cursor: 'pointer' }}>Exportar</button>
              <button style={{ height: 36, padding: '0 16px', borderRadius: 6, border: 'none', background: 'var(--brand)', color: '#FFF', fontSize: 13, fontWeight: 500, cursor: 'pointer' }}>Editar</button>
            </div>
          </div>
          <div style={{ marginTop: 20, borderBottom: '1px solid var(--border-subtle)', display: 'flex' }}>
            {['Geral', 'Drivers', 'Veículos', 'Documentos', 'Histórico'].map((t, i) => (
              <button key={i} style={{
                padding: '8px 16px', height: 36, background: 'transparent', border: 'none',
                borderBottom: '2px solid ' + (i === 0 ? 'var(--brand)' : 'transparent'),
                color: i === 0 ? 'var(--brand)' : 'var(--text-secondary)',
                fontSize: 13, fontWeight: 500, cursor: 'pointer', marginBottom: -1,
              }}>{t}{i === 1 && <span style={{ marginLeft: 6, color: 'var(--text-muted)' }}>(47)</span>}</button>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
}

window.FormDialogShowcase = FormDialogShowcase;
window.FilterBarShowcase = FilterBarShowcase;
window.RowContextMenuShowcase = RowContextMenuShowcase;
window.PageHeaderTopbarShowcase = PageHeaderTopbarShowcase;
