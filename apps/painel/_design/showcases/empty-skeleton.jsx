/* global React, YA */
const { Ico } = window.YA;

// ============== EmptyState ==============
function EmptyState({ icon, title, description, ctaLabel }) {
  return (
    <div style={{
      padding: '48px 24px', display: 'flex', flexDirection: 'column',
      alignItems: 'center', textAlign: 'center', maxWidth: 400, margin: '0 auto',
    }}>
      <div style={{
        width: 96, height: 96, borderRadius: 9999,
        background: 'var(--bg-subtle)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: 'var(--text-muted)', opacity: 0.85,
      }}>{icon}</div>
      <div style={{ fontSize: 15, fontWeight: 500, color: 'var(--text-primary)', marginTop: 16 }}>{title}</div>
      <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginTop: 8, lineHeight: 1.5 }}>{description}</div>
      {ctaLabel && (
        <button style={{
          marginTop: 20, height: 36, padding: '0 16px', borderRadius: 6,
          border: 'none', background: 'var(--brand)', color: '#FFFFFF',
          fontSize: 13, fontWeight: 500, cursor: 'pointer',
        }}>{ctaLabel}</button>
      )}
    </div>
  );
}

function EmptyStateShowcase() {
  const sectionTitle = { fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, margin: '0 0 14px' };
  const variants = [
    { icon: Ico.Building(40), title: 'Sem partners', desc: 'Convida a primeira empresa parceira para começares.', cta: 'Novo partner' },
    { icon: Ico.User(40), title: 'Sem drivers', desc: 'Convida o primeiro motorista da tua frota.', cta: 'Convidar motorista' },
    { icon: Ico.Car(40), title: 'Sem veículos', desc: 'Adiciona a primeira viatura à tua frota.', cta: 'Adicionar veículo' },
    { icon: Ico.Route(40), title: 'Sem corridas no período', desc: 'Tenta um filtro diferente ou um intervalo maior.', cta: null },
    { icon: Ico.Inbox(40), title: 'Tudo em dia', desc: 'Não há tickets na fila. Bom trabalho!', cta: null },
    { icon: Ico.Search(40), title: 'Sem resultados', desc: 'Não encontramos nada para «mondlane». Tenta termos diferentes.', cta: 'Limpar pesquisa' },
    { icon: Ico.AlertCircle(40), title: 'Erro ao carregar', desc: 'Algo correu mal. Tenta novamente em instantes.', cta: 'Tentar novamente' },
    { icon: Ico.FileText(40), title: 'Sem documentos', desc: 'Carrega documentos para começar a verificar conformidade.', cta: 'Carregar documento' },
  ];
  return (
    <section>
      <h3 style={sectionTitle}>EmptyState — variantes pré-definidas</h3>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 16 }}>
        {variants.map((v, i) => (
          <div key={i} style={{
            background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)',
            borderRadius: 8, boxShadow: 'var(--shadow-sm)', overflow: 'hidden',
          }}>
            <EmptyState icon={v.icon} title={v.title} description={v.desc} ctaLabel={v.cta} />
          </div>
        ))}
      </div>
    </section>
  );
}

// ============== Skeleton ==============
function SkeletonShowcase() {
  const sectionTitle = { fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, margin: '0 0 14px' };
  const subLabel = { fontSize: 11, color: 'var(--text-muted)', fontWeight: 400, marginBottom: 8 };
  const card = { background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)', borderRadius: 8, padding: 16, boxShadow: 'var(--shadow-sm)' };

  return (
    <section style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
      <h3 style={sectionTitle}>Skeleton — composições</h3>

      <div>
        <div style={subLabel}>Primitivas (Text · Circle · Rect)</div>
        <div style={{ ...card, display: 'flex', alignItems: 'center', gap: 16, flexWrap: 'wrap' }}>
          <div className="ya-skeleton" style={{ width: 120, height: 14 }} />
          <div className="ya-skeleton" style={{ width: 80, height: 14 }} />
          <div className="ya-skeleton" style={{ width: 32, height: 32, borderRadius: 9999 }} />
          <div className="ya-skeleton" style={{ width: 44, height: 44, borderRadius: 9999 }} />
          <div className="ya-skeleton" style={{ width: 200, height: 100, borderRadius: 6 }} />
        </div>
      </div>

      <div>
        <div style={subLabel}>SkeletonRow (linha de tabela)</div>
        <div style={{ ...card, padding: 0, overflow: 'hidden' }}>
          {[0,1,2,3].map(i => (
            <div key={i} style={{ display: 'grid', gridTemplateColumns: '120px 200px 110px 1fr 90px 130px 36px', height: 40, alignItems: 'center', borderBottom: i === 3 ? 'none' : '1px solid var(--border-subtle)', padding: '0 12px', gap: 12 }}>
              <div className="ya-skeleton" style={{ width: 90, height: 12 }} />
              <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                <div className="ya-skeleton" style={{ width: 28, height: 28, borderRadius: 9999 }} />
                <div className="ya-skeleton" style={{ width: 110, height: 12 }} />
              </div>
              <div className="ya-skeleton" style={{ width: 80, height: 12 }} />
              <div className="ya-skeleton" style={{ width: 140, height: 12 }} />
              <div className="ya-skeleton" style={{ width: 60, height: 12, marginLeft: 'auto' }} />
              <div className="ya-skeleton" style={{ width: 78, height: 22, borderRadius: 9999 }} />
              <div />
            </div>
          ))}
        </div>
      </div>

      <div>
        <div style={subLabel}>SkeletonKpi (4 cards)</div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
          {[0,1,2,3].map(i => (
            <div key={i} style={card}>
              <div className="ya-skeleton" style={{ width: 70, height: 11, marginBottom: 12 }} />
              <div className="ya-skeleton" style={{ width: 110, height: 26, marginBottom: 10 }} />
              <div className="ya-skeleton" style={{ width: 80, height: 11 }} />
            </div>
          ))}
        </div>
      </div>

      <div>
        <div style={subLabel}>SkeletonChart (gráfico de área)</div>
        <div style={card}>
          <div className="ya-skeleton" style={{ width: 140, height: 14, marginBottom: 16 }} />
          <div className="ya-skeleton" style={{ width: '100%', height: 200, borderRadius: 6 }} />
        </div>
      </div>
    </section>
  );
}

window.EmptyStateShowcase = EmptyStateShowcase;
window.SkeletonShowcase = SkeletonShowcase;
