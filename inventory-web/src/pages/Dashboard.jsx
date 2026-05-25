import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { getProducts, getLowStock } from '../api/products'
import { getCategories } from '../api/categories'
import { getMovements } from '../api/movements'
import Toast from '../components/Toast'

export default function Dashboard() {
  const [stats, setStats] = useState({
    totalProducts: 0,
    totalCategories: 0,
    totalMovements: 0,
    lowStock: []
  })
  const [movements, setMovements] = useState([])
  const [toast, setToast] = useState(null)
  const navigate = useNavigate()

  useEffect(() => {
    loadStats()
  }, [])

  const loadStats = async () => {
    try {
      const [products, categories, movementsRes, lowStock] = await Promise.all([
        getProducts(),
        getCategories(),
        getMovements(),
        getLowStock()
      ])

      setStats({
        totalProducts: products.data.length,
        totalCategories: categories.data.length,
        totalMovements: movementsRes.data.length,
        lowStock: lowStock.data
      })
      setMovements(movementsRes.data.sort((a, b) => new Date(b.created_at) - new Date(a.created_at)))
    } catch (error) {
      setToast({ type: 'error', message: 'Error cargando el dashboard. Intenta de nuevo.' })
    }
  }

  const cards = [
    { label: 'Productos', value: stats.totalProducts, icon: '📦', color: '#3b82f6', path: '/products' },
    { label: 'Categorías', value: stats.totalCategories, icon: '🏷️', color: '#8b5cf6', path: '/categories' },
    { label: 'Movimientos', value: stats.totalMovements, icon: '🔄', color: '#22c55e', path: '/movements' },
    { label: 'Stock bajo', value: stats.lowStock.length, icon: '⚠️', color: '#ef4444', path: '/products?lowstock=true' }
  ]

  const lastMovements = movements.slice(0, 5)

  return (
    <div style={{ padding: '1.5rem 0' }}>
      <Toast {...toast} onClose={() => setToast(null)} />
      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', marginBottom: '1.5rem' }}>
        <p style={{ color: '#64748b', fontSize: '0.95rem', margin: 0 }}>Panel de control</p>
        <h1 style={{ margin: 0, fontSize: '2rem', fontWeight: 700, color: '#0f172a' }}>Dashboard</h1>
      </div>

      <div style={{ display: 'grid', gap: '1rem', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', marginBottom: '1.75rem' }}>
        {cards.map((card) => (
          <button
            key={card.label}
            type="button"
            onClick={() => navigate(card.path)}
            style={{
              textAlign: 'left',
              background: '#ffffff',
              border: '1px solid #e2e8f0',
              borderRadius: '18px',
              boxShadow: '0 18px 45px rgba(15, 23, 42, 0.06)',
              padding: '1.5rem',
              cursor: 'pointer',
              display: 'flex',
              flexDirection: 'column',
              gap: '1rem'
            }}
          >
            <div style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', width: '44px', height: '44px', borderRadius: '14px', background: `${card.color}20`, color: card.color, fontSize: '1.2rem' }}>
              {card.icon}
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', gap: '1rem' }}>
              <div>
                <p style={{ margin: 0, color: '#0f172a', fontWeight: 700, fontSize: '1.7rem' }}>{card.value}</p>
                <p style={{ margin: 0, color: '#64748b', fontSize: '0.95rem' }}>{card.label}</p>
              </div>
            </div>
          </button>
        ))}
      </div>

      <div style={{ display: 'grid', gap: '1.5rem', gridTemplateColumns: '1.2fr 0.8fr' }}>
        <section style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '22px', boxShadow: '0 18px 45px rgba(15, 23, 42, 0.06)', padding: '1.5rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <div>
              <h2 style={{ margin: 0, fontSize: '1.1rem', fontWeight: 700, color: '#0f172a' }}>Últimos movimientos</h2>
              <p style={{ margin: 0, color: '#64748b', fontSize: '0.95rem' }}>Revisa los cinco movimientos más recientes.</p>
            </div>
          </div>
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: '620px' }}>
              <thead>
                <tr style={{ textAlign: 'left' }}>
                  {['Producto', 'Tipo', 'Cantidad', 'Referencia', 'Fecha'].map((title) => (
                    <th key={title} style={{ padding: '0.95rem 1rem', borderBottom: '1px solid #e2e8f0', color: '#64748b', fontSize: '0.9rem' }}>{title}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {lastMovements.map((movement) => {
                  const typeColors = movement.type === 'entrada' ? { background: '#dcfce7', color: '#166534' } : movement.type === 'salida' ? { background: '#fee2e2', color: '#b91c1c' } : { background: '#fef3c7', color: '#92400e' }
                  return (
                    <tr key={movement.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                      <td style={{ padding: '0.95rem 1rem', color: '#0f172a', fontWeight: 500 }}>{movement.product_name || movement.product?.name || 'Producto'}</td>
                      <td style={{ padding: '0.95rem 1rem' }}>
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', padding: '0.35rem 0.75rem', borderRadius: '999px', background: typeColors.background, color: typeColors.color, fontSize: '0.82rem', fontWeight: 600, textTransform: 'capitalize' }}>{movement.type}</span>
                      </td>
                      <td style={{ padding: '0.95rem 1rem', color: '#0f172a' }}>{movement.quantity}</td>
                      <td style={{ padding: '0.95rem 1rem', color: '#64748b' }}>{movement.reference || '—'}</td>
                      <td style={{ padding: '0.95rem 1rem', color: '#64748b' }}>{new Date(movement.created_at).toLocaleDateString()}</td>
                    </tr>
                  )
                })}
                {lastMovements.length === 0 && (
                  <tr>
                    <td colSpan="5" style={{ padding: '1.5rem', textAlign: 'center', color: '#94a3b8' }}>No hay movimientos recientes.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>

        <section style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '22px', boxShadow: '0 18px 45px rgba(15, 23, 42, 0.06)', padding: '1.5rem' }}>
          <div style={{ marginBottom: '1rem' }}>
            <h2 style={{ margin: 0, fontSize: '1.1rem', fontWeight: 700, color: '#0f172a' }}>Productos con stock bajo</h2>
            <p style={{ margin: 0, color: '#64748b', fontSize: '0.95rem' }}>Mantén controladas las existencias más críticas.</p>
          </div>
          <div style={{ display: 'grid', gap: '0.9rem' }}>
            {stats.lowStock.map((product) => (
              <div key={product.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '1rem', padding: '1rem', border: '1px solid #e2e8f0', borderRadius: '16px' }}>
                <div>
                  <p style={{ margin: 0, fontWeight: 700, color: '#0f172a' }}>{product.name}</p>
                  <p style={{ margin: 0, color: '#64748b', fontSize: '0.92rem' }}>{product.category?.name || 'Sin categoría'}</p>
                </div>
                <span style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', minWidth: '92px', padding: '0.5rem 0.75rem', borderRadius: '999px', background: '#fee2e2', color: '#b91c1c', fontWeight: 700 }}>{product.stock} {product.unit || 'u'}</span>
              </div>
            ))}
            {stats.lowStock.length === 0 && (
              <div style={{ padding: '1rem', border: '1px solid #e2e8f0', borderRadius: '16px', color: '#0f172a' }}>No hay alertas de stock bajo.</div>
            )}
          </div>
        </section>
      </div>
    </div>
  )
}
