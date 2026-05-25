import { useLocation } from 'react-router-dom'
import { Link } from 'react-router-dom'
import { useState, useEffect } from 'react'

const navItems = [
  { label: 'Dashboard', to: '/' },
  { label: 'Productos', to: '/products' },
  { label: 'Categorías', to: '/categories' },
  { label: 'Movimientos', to: '/movements' }
]

export default function Navbar({ onLogout }) {
  const location = useLocation()
  const [userRole, setUserRole] = useState(null)

  useEffect(() => {
    const token = localStorage.getItem('token')
    if (token) {
      try {
        const payload = JSON.parse(atob(token.split('.')[1]))
        setUserRole(payload.role)
      } catch (e) {
        console.error('Error parsing token:', e)
      }
    }
  }, [])

  const isActive = (path) => path === '/' ? location.pathname === '/' : location.pathname.startsWith(path)

  return (
    <header style={{ background: '#ffffff', borderBottom: '1px solid #e2e8f0', boxShadow: '0 10px 30px rgba(15, 23, 42, 0.06)' }}>
      <div style={{ width: '100%', maxWidth: '1400px', margin: '0 auto', padding: '0.75rem 1rem', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '1rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.9rem' }}>
          <div style={{ width: '42px', height: '42px', borderRadius: '14px', background: '#e0e7ff', display: 'grid', placeItems: 'center' }}>
            <span style={{ fontSize: '1.2rem' }}>🏬</span>
          </div>
          <Link to="/" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.5rem', color: '#1e40af', fontWeight: 700, fontSize: '1.05rem', textDecoration: 'none' }}>
            Inventory
          </Link>
        </div>

        <nav style={{ display: 'flex', alignItems: 'center', gap: '1.25rem' }}>
          {navItems.map((item) => (
            <Link
              key={item.to}
              to={item.to}
              style={{
                color: isActive(item.to) ? '#1e40af' : '#64748b',
                textDecoration: 'none',
                padding: '0.4rem 0',
                borderBottom: isActive(item.to) ? '2px solid #1e40af' : '2px solid transparent',
                fontWeight: 500
              }}
            >
              {item.label}
            </Link>
          ))}
          {userRole === 'admin' && (
            <Link
              to="/users"
              style={{
                color: isActive('/users') ? '#1e40af' : '#64748b',
                textDecoration: 'none',
                padding: '0.4rem 0',
                borderBottom: isActive('/users') ? '2px solid #1e40af' : '2px solid transparent',
                fontWeight: 500
              }}
            >
              Usuarios
            </Link>
          )}
        </nav>

        <button
          onClick={onLogout}
          style={{ background: '#ef4444', color: 'white', border: 'none', padding: '0.65rem 1rem', borderRadius: '999px', cursor: 'pointer', fontWeight: 600 }}
        >
          Cerrar sesión
        </button>
      </div>
    </header>
  )
}
