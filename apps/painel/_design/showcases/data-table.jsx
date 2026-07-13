/* global React, YA */
const { StatusBadge, Ico } = window.YA;
const { useState } = React;

function Avatar({ initial, size = 28, hue = 200 }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: 9999,
      background: `oklch(0.32 0.05 ${hue})`,
      color: 'var(--text-primary)',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      fontSize: 11, fontWeight: 500, letterSpacing: '0.02em',
      border: '1.5px solid var(--border-subtle)', flexShrink: 0,
    }}>{initial}</div>
  );
}

function PersonCell({ name, sub, initial, hue }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, minWidth: 0 }}>
      <Avatar initial={initial} hue={hue} />
      <div style={{ minWidth: 0 }}>
        <div style={{ fontSize: 13, color: 'var(--text-primary)', fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{name}</div>
        <div className="ya-mono" style={{ fontSize: 11, color: 'var(--text-muted)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{sub}</div>
      </div>
    </div>
  );
}

const TRIPS = [
  { id: 'TRP-2847A1', driver: 'A. Macuvele', driverInit: 'AM', hue: 30,  vehicle: 'AAA-123-MP', from: 'Polana', to: 'Aeroporto', dist: '12,4 km', dur: '25 min', amount: '850', status: 'completed', label: 'Completa', when: 'há 12 min' },
  { id: 'TRP-2847A2', driver: 'B. Sitoe',    driverInit: 'BS', hue: 120, vehicle: 'BBC-456-MP', from: 'Baixa',  to: 'Costa do Sol', dist: '8,1 km',  dur: '18 min', amount: '620', status: 'started',   label: 'A decorrer', when: 'há 4 min' },
  { id: 'TRP-2847A3', driver: 'C. Mondlane', driverInit: 'CM', hue: 280, vehicle: 'AAB-789-MP', from: 'Sommerschield', to: 'Matola', dist: '18,7 km', dur: '42 min', amount: '1 240', status: 'cancelled', label: 'Cancelada', when: 'há 28 min' },
  { id: 'TRP-2847A4', driver: 'D. Tembe',    driverInit: 'DT', hue: 200, vehicle: 'CAA-222-MP', from: 'Maxaquene', to: 'Polana', dist: '5,2 km',  dur: '14 min', amount: '480', status: 'completed', label: 'Completa', when: 'há 45 min' },
  { id: 'TRP-2847A5', driver: 'E. Nhantumbo', driverInit: 'EN', hue: 60,  vehicle: 'BBA-901-MP', from: 'Aeroporto', to: 'Hotel Cardoso', dist: '7,8 km', dur: '22 min', amount: '720', status: 'accepted', label: 'Aceite', when: 'há 1 min' },
];

function DataTable({ density = 'comfortable', loading = false, empty = false, selectable = false, selected = [] }) {
  const rowH = density === 'compact' ? 32 : 40;
  const [sortBy, setSortBy] = useState('when');
  const [sortDir, setSortDir] = useState('desc');
  const [hoveredRow, setHoveredRow] = useState(null);
  const [selectedSet, setSelectedSet] = useState(new Set(selected));

  const cols = [
    selectable && { key: '_select', label: '', width: 36 },
    { key: 'id', label: 'ID', width: 124 },
    { key: 'driver', label: 'Driver', width: 200 },
    { key: 'vehicle', label: 'Matrícula', width: 120 },
    { key: 'route', label: 'Rota', width: 220 },
    { key: 'dist', label: 'Distância', width: 90, align: 'right' },
    { key: 'amount', label: 'Valor', width: 110, align: 'right' },
    { key: 'status', label: 'Estado', width: 130 },
    { key: 'when', label: 'Quando', width: 110 },
    { key: '_more', label: '', width: 36 },
  ].filter(Boolean);

  const headerCellBase = {
    height: 40, padding: '0 12px',
    fontSize: 11, fontWeight: 500, color: 'var(--text-secondary)',
    letterSpacing: '0.02em', textTransform: 'uppercase',
    display: 'flex', alignItems: 'center', gap: 4,
    background: 'var(--bg-surface)',
    borderBottom: '1px solid var(--border-subtle)',
    userSelect: 'none',
  };

  const renderHeader = () => (
    <div style={{ display: 'grid', gridTemplateColumns: cols.map(c => c.width ? `${c.width}px` : '1fr').join(' '), position: 'sticky', top: 0, zIndex: 2 }}>
      {cols.map((c, i) => {
        const sortable = !['_select', '_more', 'route'].includes(c.key);
        const isSorted = sortBy === c.key;
        return (
          <div key={i} style={{ ...headerCellBase, justifyContent: c.align === 'right' ? 'flex-end' : 'flex-start', cursor: sortable ? 'pointer' : 'default' }}
               onClick={() => { if (sortable) { setSortBy(c.key); setSortDir(isSorted && sortDir === 'asc' ? 'desc' : 'asc'); } }}>
            {c.key === '_select' ? (
              <input type="checkbox" style={{ accentColor: 'var(--brand)' }} />
            ) : (
              <>
                <span>{c.label}</span>
                {sortable && (
                  <span style={{ color: isSorted ? 'var(--text-primary)' : 'var(--text-muted)', opacity: isSorted ? 1 : 0.5, display: 'inline-flex' }}>
                    {isSorted && sortDir === 'asc' ? Ico.ChevronUp() : Ico.ChevronDown()}
                  </span>
                )}
              </>
            )}
          </div>
        );
      })}
    </div>
  );

  if (empty) {
    return (
      <div style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)', borderRadius: 8, overflow: 'hidden', boxShadow: 'var(--shadow-sm)' }}>
        {renderHeader()}
        <div style={{ padding: '48px 24px', display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
          <div style={{ width: 96, height: 96, borderRadius: 9999, background: 'var(--bg-subtle)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-muted)' }}>
            {Ico.Inbox(40)}
          </div>
          <div style={{ fontSize: 15, fontWeight: 500, color: 'var(--text-primary)', marginTop: 16 }}>Sem corridas no período</div>
          <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginTop: 8, maxWidth: 320, lineHeight: 1.5 }}>
            Tenta um filtro diferente ou alarga o intervalo de datas para ver mais resultados.
          </div>
        </div>
      </div>
    );
  }

  return (
    <div style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)', borderRadius: 8, overflow: 'hidden', boxShadow: 'var(--shadow-sm)' }}>
      {renderHeader()}
      <div>
        {loading ? (
          [0,1,2,3,4].map(i => (
            <div key={i} style={{ display: 'grid', gridTemplateColumns: cols.map(c => c.width ? `${c.width}px` : '1fr').join(' '), height: rowH, alignItems: 'center', borderBottom: i === 4 ? 'none' : '1px solid var(--border-subtle)' }}>
              {cols.map((c, j) => (
                <div key={j} style={{ padding: '0 12px' }}>
                  {c.key === '_select' ? <div className="ya-skeleton" style={{ width: 14, height: 14, borderRadius: 3 }} /> :
                   c.key === 'driver' ? <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}><div className="ya-skeleton" style={{ width: 28, height: 28, borderRadius: 9999 }} /><div className="ya-skeleton" style={{ width: 110, height: 12 }} /></div> :
                   c.key === 'status' ? <div className="ya-skeleton" style={{ width: 78, height: 22, borderRadius: 9999 }} /> :
                   c.key === '_more' ? null : <div className="ya-skeleton" style={{ width: c.align === 'right' ? 60 : 90, height: 12, marginLeft: c.align === 'right' ? 'auto' : 0 }} />}
                </div>
              ))}
            </div>
          ))
        ) : TRIPS.map((row, i) => {
          const isSelected = selectedSet.has(row.id);
          const isHover = hoveredRow === row.id;
          const bg = isSelected ? 'var(--brand-subtle)' : isHover ? 'var(--bg-subtle)' : 'transparent';
          const variant = row.status === 'completed' ? 'success' : row.status === 'started' ? 'warning' : row.status === 'cancelled' ? 'danger' : row.status === 'accepted' ? 'info' : 'neutral';
          return (
            <div key={row.id}
                 onMouseEnter={() => setHoveredRow(row.id)}
                 onMouseLeave={() => setHoveredRow(null)}
                 style={{ display: 'grid', gridTemplateColumns: cols.map(c => c.width ? `${c.width}px` : '1fr').join(' '), height: rowH, alignItems: 'center', borderBottom: i === TRIPS.length - 1 ? 'none' : '1px solid var(--border-subtle)', background: bg, cursor: 'pointer', transition: 'background 100ms' }}>
              {selectable && (
                <div style={{ padding: '0 12px' }}>
                  <input type="checkbox" checked={isSelected} onChange={() => {
                    const n = new Set(selectedSet); isSelected ? n.delete(row.id) : n.add(row.id); setSelectedSet(n);
                  }} style={{ accentColor: 'var(--brand)' }} />
                </div>
              )}
              <div style={{ padding: '0 12px' }}><span className="ya-mono" style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{row.id}</span></div>
              <div style={{ padding: '0 12px' }}><PersonCell name={row.driver} sub={row.driverInit.toLowerCase() + '@ya.mz'} initial={row.driverInit} hue={row.hue} /></div>
              <div style={{ padding: '0 12px' }}><span className="ya-mono" style={{ fontSize: 12, color: 'var(--text-primary)' }}>{row.vehicle}</span></div>
              <div style={{ padding: '0 12px', minWidth: 0 }}>
                <div style={{ fontSize: 13, color: 'var(--text-primary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{row.from} → {row.to}</div>
              </div>
              <div style={{ padding: '0 12px', textAlign: 'right' }}><span className="ya-tnum" style={{ fontSize: 13, color: 'var(--text-secondary)' }}>{row.dist}</span></div>
              <div style={{ padding: '0 12px', textAlign: 'right' }}><span className="ya-mono ya-tnum" style={{ fontSize: 13, color: 'var(--text-primary)', fontWeight: 500 }}>{row.amount}</span> <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>MTn</span></div>
              <div style={{ padding: '0 12px' }}><StatusBadge variant={variant} label={row.label} /></div>
              <div style={{ padding: '0 12px' }}><span style={{ fontSize: 12, color: 'var(--text-muted)' }}>{row.when}</span></div>
              <div style={{ padding: '0 12px', display: 'flex', justifyContent: 'flex-end' }}>
                <button style={{
                  width: 28, height: 28, borderRadius: 6, border: 'none',
                  background: isHover ? 'var(--bg-elevated)' : 'transparent',
                  color: 'var(--text-secondary)', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                  opacity: isHover ? 1 : 0.5,
                }} aria-label="Mais">{Ico.More(16)}</button>
              </div>
            </div>
          );
        })}
      </div>
      {/* Footer */}
      <div style={{ padding: '12px 16px', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: 'var(--bg-surface)' }}>
        <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{loading ? 'A carregar...' : empty ? 'Sem resultados' : 'A mostrar 1–5 de 247'}</span>
        <div style={{ display: 'flex', gap: 4 }}>
          {['‹‹', '‹', '1', '2', '3', '›', '››'].map((p, i) => {
            const active = p === '1';
            return (
              <button key={i} style={{
                minWidth: 28, height: 28, padding: '0 8px', borderRadius: 6,
                background: active ? 'var(--brand-subtle)' : 'transparent',
                color: active ? 'var(--brand)' : 'var(--text-secondary)',
                border: active ? 'none' : '1px solid transparent',
                fontSize: 12, fontWeight: active ? 500 : 400, cursor: 'pointer',
              }}>{p}</button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

function FilterBar({ activeIdx = 0 }) {
  const chips = [
    { label: 'Todas', count: 247, variant: 'neutral' },
    { label: 'A decorrer', count: 24, variant: 'warning' },
    { label: 'Completas', count: 198, variant: 'success' },
    { label: 'Canceladas', count: 17, variant: 'danger' },
    { label: 'Aceites', count: 8, variant: 'info' },
  ];
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 16 }}>
      <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
        <div style={{ position: 'relative', flex: 1, maxWidth: 320 }}>
          <span style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', display: 'inline-flex' }}>{Ico.Search()}</span>
          <input placeholder="Pesquisar por ID, driver ou matrícula..." style={{
            width: '100%', height: 32, paddingLeft: 32, paddingRight: 12,
            borderRadius: 6, border: '1px solid var(--border-default)',
            background: 'var(--bg-surface)', color: 'var(--text-primary)',
            fontSize: 13, fontFamily: 'inherit', outline: 'none',
          }} />
        </div>
        <button style={{
          height: 32, padding: '0 12px', borderRadius: 6,
          border: '1px solid var(--border-default)', background: 'transparent',
          color: 'var(--text-primary)', fontSize: 13, fontWeight: 500, cursor: 'pointer',
        }}>Filtros</button>
      </div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
        {chips.map((c, i) => {
          const active = i === activeIdx;
          return (
            <button key={i} style={{
              height: 28, padding: '0 12px', borderRadius: 9999,
              border: '1px solid ' + (active ? 'var(--brand-border)' : 'var(--border-subtle)'),
              background: active ? 'var(--brand-subtle)' : 'transparent',
              color: active ? 'var(--brand)' : 'var(--text-secondary)',
              fontSize: 12, fontWeight: active ? 500 : 400,
              display: 'inline-flex', alignItems: 'center', gap: 6, cursor: 'pointer',
              transition: 'all 150ms',
            }}>
              {c.label} <span style={{ opacity: 0.7, fontSize: 11 }} className="ya-tnum">{c.count}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

function DataTableShowcase() {
  const sectionTitle = { fontSize: 11, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-muted)', fontWeight: 500, margin: '0 0 12px' };
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 28 }}>
      <section>
        <h3 style={sectionTitle}>Default — com FilterBar, hover, sort, paginação</h3>
        <FilterBar activeIdx={0} />
        <DataTable />
      </section>
      <section>
        <h3 style={sectionTitle}>Selectable — bulk actions activadas (linha 2 selected)</h3>
        <DataTable selectable selected={['TRP-2847A2']} />
      </section>
      <section>
        <h3 style={sectionTitle}>Loading — 5 linhas skeleton</h3>
        <DataTable loading />
      </section>
      <section>
        <h3 style={sectionTitle}>Empty state</h3>
        <DataTable empty />
      </section>
    </div>
  );
}

window.DataTableShowcase = DataTableShowcase;
window.DataTable = DataTable;
