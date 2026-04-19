import { Link } from 'react-router-dom'

export default function Navbar({ onLogout }) {
  return (
    <nav style={{ background: '#1e293b', padding: '1rem 2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
      <div style={{ display: 'flex', gap: '1.5rem' }}>
        <Link to="/" style={{ color: 'white', textDecoration: 'none', fontWeight: 'bold' }}>🏪 Inventory</Link>
        <Link to="/products" style={{ color: '#94a3b8', textDecoration: 'none' }}>Productos</Link>
        <Link to="/categories" style={{ color: '#94a3b8', textDecoration: 'none' }}>Categorías</Link>
        <Link to="/movements" style={{ color: '#94a3b8', textDecoration: 'none' }}>Movimientos</Link>
      </div>
      <button
        onClick={onLogout}
        style={{ background: '#ef4444', color: 'white', border: 'none', padding: '0.5rem 1rem', borderRadius: '4px', cursor: 'pointer' }}
      >
        Cerrar sesión
      </button>
    </nav>
  )
}