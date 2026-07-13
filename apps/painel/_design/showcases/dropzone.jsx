/* global React, YA */
const { Ico } = window.YA;

// ============== FileDropzone ==============
function Zone({ state, label, sub, file, progress, errorMsg }) {
  let border = '2px dashed var(--border-default)';
  let bg = 'var(--bg-surface)';
  let iconColor = 'var(--text-muted)';
  if (state === 'hover') { border = '2px dashed var(--brand-border)'; bg = 'var(--brand-subtle)'; iconColor = 'var(--brand)'; }
  if (state === 'success') { border = '2px solid var(--success-border)'; bg = 'var(--success-subtle)'; iconColor = 'var(--success)'; }
  if (state === 'error') { border = '2px solid var(--danger-border)'; bg = 'var(--danger-subtle)'; iconColor = 'var(--danger)'; }
  if (state === 'uploading') { border = '2px solid var(--brand-border)'; bg = 'var(--bg-surface)'; iconColor = 'var(--brand)'; }

  const icon = state === 'success' ? Ico.Check(28)
    : state === 'error' ? Ico.Alert(28)
    : state === 'uploading' ? Ico.FileText(28)
    : Ico.Up(28);

  return (
    <div style={{
      padding: 24, borderRadius: 8, border, background: bg,
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      minHeight: 180, gap: 12, transition: 'all 120ms',
    }}>
      <div style={{
        width: 56, height: 56, borderRadius: 9999,
        background: state === 'success' ? 'rgba(34,197,94,0.15)' : state === 'error' ? 'rgba(239,68,68,0.15)' : 'var(--bg-subtle)',
        color: iconColor, display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>{icon}</div>
      <div style={{ textAlign: 'center' }}>
        <div style={{ fontSize: 14, fontWeight: 500, color: 'var(--text-primary)' }}>{label}</div>
        {sub && <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 4 }}>{sub}</div>}
      </div>

      {state === 'uploading' && (
        <div style={{ width: '100%', maxWidth: 320 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, color: 'var(--text-secondary)', marginBottom: 6 }}>
            <span className="ya-mono">{file}</span>
            <span className="ya-mono">{progress}%</span>
          </div>
          <div style={{ height: 6, borderRadius: 9999, background: 'var(--bg-subtle)', overflow: 'hidden' }}>
            <div style={{ width: `${progress}%`, height: '100%', background: 'var(--brand)', borderRadius: 9999 }} />
          </div>
        </div>
      )}
      {state === 'success' && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, color: 'var(--text-secondary)' }}>
          <span className="ya-mono">{file}</span>
          <button style={{ border: 'none', background: 'transparent', color: 'var(--text-muted)', cursor: 'pointer', display: 'inline-flex' }}>{Ico.X(12)}</button>
        </div>
      )}
      {state === 'error' && errorMsg && (
        <div style={{ fontSize: 12, color: 'var(--danger)', textAlign: 'center' }}>{errorMsg}</div>
      )}
    </div>
  );
}

function FileDropzoneShowcase() {
  const sectionTitle = { fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, margin: '0 0 14px' };
  return (
    <section>
      <h3 style={sectionTitle}>FileDropzone — 4 estados</h3>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 16 }}>
        <Zone state="idle" label="Arrasta o ficheiro ou clica para escolher" sub="PDF, JPG, PNG · máx 10MB" />
        <Zone state="hover" label="Larga aqui o ficheiro" sub="PDF, JPG, PNG · máx 10MB" />
        <Zone state="uploading" label="A carregar..." file="carta_conducao.pdf" progress={64} />
        <Zone state="success" label="Documento carregado" file="carta_conducao.pdf · 2.4 MB" />
        <div style={{ gridColumn: 'span 2' }}>
          <Zone state="error" label="Falha no upload" sub="Verifica o ficheiro e tenta novamente" errorMsg="Ficheiro maior que 10MB (recebido: 14.2MB)" />
        </div>
      </div>
    </section>
  );
}

window.FileDropzoneShowcase = FileDropzoneShowcase;
