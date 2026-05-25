export default function Toast({ type = 'success', message, onClose }) {
  if (!message) return null

  const styles = {
    success: { background: '#dcfce7', color: '#166534' },
    error: { background: '#fee2e2', color: '#991b1b' }
  }

  return (
    <div style={{ position: 'fixed', top: '1rem', right: '1rem', zIndex: 60, width: 'min(100%, 360px)' }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: '1rem', padding: '1rem 1rem 1rem 1rem', borderRadius: '18px', boxShadow: '0 18px 45px rgba(15, 23, 42, 0.12)', ...styles[type] }}>
        <div style={{ display: 'grid', gap: '0.25rem' }}>
          <span style={{ fontWeight: 700 }}>{type === 'success' ? 'Éxito' : 'Error'}</span>
          <span style={{ color: 'inherit' }}>{message}</span>
        </div>
        <button onClick={onClose} style={{ border: 'none', background: 'transparent', fontSize: '1.1rem', fontWeight: 700, color: 'inherit', cursor: 'pointer' }} aria-label="Cerrar mensaje">×</button>
      </div>
    </div>
  )
}
