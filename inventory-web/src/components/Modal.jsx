export default function Modal({ open, title, onClose, children }) {
  if (!open) return null

  return (
    <div style={{ position: 'fixed', inset: 0, zIndex: 50, background: 'rgba(15, 23, 42, 0.42)', display: 'flex', alignItems: 'flex-start', justifyContent: 'center', padding: '2rem' }}>
      <div style={{ width: '100%', maxWidth: '760px', background: '#ffffff', borderRadius: '24px', boxShadow: '0 25px 50px rgba(15, 23, 42, 0.18)', overflow: 'hidden' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1.25rem 1.5rem', borderBottom: '1px solid #e2e8f0' }}>
          <h2 style={{ margin: 0, fontSize: '1.1rem', color: '#0f172a' }}>{title}</h2>
          <button onClick={onClose} style={{ border: 'none', background: 'transparent', fontSize: '1.4rem', fontWeight: 700, color: '#475569', cursor: 'pointer' }} aria-label="Cerrar modal">×</button>
        </div>
        <div style={{ padding: '1.5rem' }}>{children}</div>
      </div>
    </div>
  )
}
